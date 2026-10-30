import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/backend_api_client.dart';

class RouteVisitService {
  final BackendApiClient _api = BackendApiClient();

  String get _storageKey {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'rutaamiga_passport_visits_v1_$userId';
  }

  Future<Map<String, dynamic>> register({
    required Map<String, dynamic> stop,
    required String routeId,
    required Position position,
    required int rating,
    required String comment,
    String? placeCondition,
    String? accessCondition,
    File? photo,
  }) async {
    final clientId = const Uuid().v4();
    final payload = <String, dynamic>{
      'client_visit_id': clientId,
      'route_id': routeId,
      'place_id': stop['id']?.toString() ?? stop['name'].toString(),
      'place_name': stop['name']?.toString() ?? 'Parada',
      'place_category': stop['category']?.toString() ?? '',
      'place_region': [stop['district'], stop['province'], stop['department']]
          .where((value) => (value?.toString().trim() ?? '').isNotEmpty)
          .join(', '),
      'place_source': stop['source'] == 'community' ? 'community' : 'official',
      'target_latitude': (stop['latitude'] as num).toDouble(),
      'target_longitude': (stop['longitude'] as num).toDouble(),
      'recorded_latitude': position.latitude,
      'recorded_longitude': position.longitude,
      'gps_accuracy_m': position.accuracy,
      'rating': rating,
      'comment': comment,
      if (placeCondition != null) 'place_condition': placeCondition,
      if (accessCondition != null) 'access_condition': accessCondition,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final result = await _send(payload, photo: photo);
      await _upsertLocal({...result, 'sync_status': 'synced'});
      return result;
    } catch (_) {
      final persistentPhotoPath = await _persistPendingPhoto(photo, clientId);
      final radius = _verificationRadius(
        payload['place_name'].toString(),
        payload['place_category'].toString(),
      );
      final distance = Geolocator.distanceBetween(
        payload['target_latitude'] as double,
        payload['target_longitude'] as double,
        position.latitude,
        position.longitude,
      );
      final queued = {
        ...payload,
        'id': 'local-$clientId',
        'distance_m': distance,
        'verification_radius_m': radius,
        'visit_verified': distance <= radius && position.accuracy <= 120,
        'photo_local_path': persistentPhotoPath,
        'sync_status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _upsertLocal(queued);
      return queued;
    }
  }

  Future<Map<String, dynamic>?> conditions(String placeId) async {
    try {
      return Map<String, dynamic>.from(
        await _api.get('/places/$placeId/conditions') as Map,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> passport() async {
    await syncPending();
    try {
      final response = await _api.get('/visits', query: {'limit': 200});
      final remote = (response as List)
          .map(
            (item) => {
              ...Map<String, dynamic>.from(item as Map),
              'sync_status': 'synced',
            },
          )
          .toList();
      final pending = (await _local()).where(
        (item) => item['sync_status'] == 'pending',
      );
      final combined = <String, Map<String, dynamic>>{
        for (final item in [...pending, ...remote])
          item['client_visit_id'].toString(): item,
      }.values.toList();
      combined.sort(
        (a, b) => (b['captured_at']?.toString() ?? '').compareTo(
          a['captured_at']?.toString() ?? '',
        ),
      );
      await _saveLocal(combined);
      return combined;
    } catch (_) {
      return _local();
    }
  }

  Future<void> syncPending() async {
    final items = await _local();
    var changed = false;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item['sync_status'] != 'pending') continue;
      final photoPath = item['photo_local_path']?.toString();
      try {
        final result = await _send(
          Map<String, dynamic>.from(item)
            ..remove('id')
            ..remove('distance_m')
            ..remove('verification_radius_m')
            ..remove('visit_verified')
            ..remove('photo_local_path')
            ..remove('sync_status')
            ..remove('created_at'),
          photo: photoPath == null ? null : File(photoPath),
        );
        items[index] = {...result, 'sync_status': 'synced'};
        await _deletePendingPhoto(photoPath);
        changed = true;
      } catch (_) {
        // La cola permanece disponible para el siguiente intento.
      }
    }
    if (changed) await _saveLocal(items);
  }

  Future<Map<String, dynamic>> _send(
    Map<String, dynamic> payload, {
    File? photo,
  }) async {
    final body = Map<String, dynamic>.from(payload);
    if (photo != null && await photo.exists()) {
      final filename = path.basename(photo.path);
      final contentType = _contentType(filename);
      final presign = Map<String, dynamic>.from(
        await _api.post(
              '/uploads/presign',
              body: {
                'filename': filename,
                'content_type': contentType,
                'size_bytes': await photo.length(),
              },
            )
            as Map,
      );
      await _api.uploadFile(
        uploadUrl: presign['upload_url'].toString(),
        file: photo,
        headers: Map<String, String>.from(presign['required_headers'] as Map),
      );
      body['photo_object_key'] = presign['object_key'];
    }
    return Map<String, dynamic>.from(
      await _api.post('/visits', body: body) as Map,
    );
  }

  Future<List<Map<String, dynamic>>> _local() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _upsertLocal(Map<String, dynamic> visit) async {
    final items = await _local();
    final clientId = visit['client_visit_id']?.toString();
    items.removeWhere(
      (item) => item['client_visit_id']?.toString() == clientId,
    );
    items.insert(0, visit);
    await _saveLocal(items);
  }

  Future<void> _saveLocal(List<Map<String, dynamic>> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(items));
  }

  Future<String?> _persistPendingPhoto(File? photo, String clientId) async {
    if (photo == null || !await photo.exists()) return null;
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      path.join(root.path, 'rutaamiga', 'pending_visits'),
    );
    await directory.create(recursive: true);
    final extension = path.extension(photo.path).toLowerCase();
    final destination = File(
      path.join(
        directory.path,
        '$clientId${extension.isEmpty ? '.jpg' : extension}',
      ),
    );
    if (path.equals(photo.path, destination.path)) return destination.path;
    await photo.copy(destination.path);
    return destination.path;
  }

  Future<void> _deletePendingPhoto(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return;
    final file = File(photoPath);
    if (await file.exists()) await file.delete();
  }

  static double _verificationRadius(String name, String category) {
    final text = '$name $category'.toLowerCase();
    if (text.contains('nevado') ||
        text.contains('montaña') ||
        text.contains('montana') ||
        text.contains('volcán') ||
        text.contains('volcan')) {
      return 500;
    }
    if (text.contains('cascada') ||
        text.contains('bosque') ||
        text.contains('lago') ||
        text.contains('playa') ||
        text.contains('desierto')) {
      return 300;
    }
    return 180;
  }

  static String _contentType(String filename) {
    final extension = path.extension(filename).toLowerCase();
    if (extension == '.png') return 'image/png';
    if (extension == '.webp') return 'image/webp';
    return 'image/jpeg';
  }
}
