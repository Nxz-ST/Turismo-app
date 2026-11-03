import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/backend_api_client.dart';
import '../../../core/errors/friendly_error.dart';

class ReportPlaceService {
  final BackendApiClient _api = BackendApiClient();
  static bool _syncInProgress = false;

  String get _queueKey {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'rutaamiga_pending_evidences_v1_$userId';
  }

  Future<Map<String, dynamic>> submitAndProcess({
    required File imageFile,
    required String nombre,
    required String descripcion,
    required double latitud,
    required double longitud,
    required double altitud,
    required double gpsAccuracy,
    required String captureSource,
    required DateTime capturedAt,
    String? presenceSampleId,
    int? targetPlaceId,
    String? targetCommunityPlaceId,
  }) async {
    final clientEvidenceId = const Uuid().v4();
    final filename = path.basename(imageFile.path);
    final contentType = _contentType(filename);
    final contentHash = await sha256.bind(imageFile.openRead()).first;
    final payload = <String, dynamic>{
      'client_evidence_id': clientEvidenceId,
      'original_filename': filename,
      'mime_type': contentType,
      'name': nombre,
      'description': descripcion,
      'latitude': latitud,
      'longitude': longitud,
      'altitude': altitud,
      'gps_accuracy_m': gpsAccuracy,
      'capture_source': captureSource,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'content_hash': contentHash.toString(),
      if (presenceSampleId != null) 'presence_sample_id': presenceSampleId,
      'contribution_type':
          targetPlaceId == null && targetCommunityPlaceId == null
          ? 'new_place'
          : 'existing_place',
      if (targetPlaceId != null) 'target_place_id': targetPlaceId,
      if (targetCommunityPlaceId != null)
        'target_community_place_id': targetCommunityPlaceId,
    };

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.every((result) => result == ConnectivityResult.none)) {
      return _queueOffline(imageFile: imageFile, payload: payload);
    }

    try {
      return await _send(imageFile: imageFile, payload: payload);
    } on BackendApiException catch (error) {
      if (!error.isNetworkFailure) rethrow;
      return _queueOffline(imageFile: imageFile, payload: payload);
    }
  }

  Future<Map<String, dynamic>> _send({
    required File imageFile,
    required Map<String, dynamic> payload,
  }) async {
    final filename = payload['original_filename'].toString();
    final contentType = payload['mime_type'].toString();
    final presign = Map<String, dynamic>.from(
      await _api.post(
            '/uploads/presign',
            body: {
              'filename': filename,
              'content_type': contentType,
              'size_bytes': await imageFile.length(),
            },
          )
          as Map,
    );
    await _api.uploadFile(
      uploadUrl: presign['upload_url'].toString(),
      file: imageFile,
      headers: Map<String, String>.from(presign['required_headers'] as Map),
    );

    final evidencePayload = Map<String, dynamic>.from(payload)
      ..['object_key'] = presign['object_key'];
    final evidence = Map<String, dynamic>.from(
      await _api.post('/evidences', body: evidencePayload) as Map,
    );

    final evidenceId = evidence['id'].toString();
    await _api.post('/evidences/$evidenceId/process');
    return {
      ...evidence,
      'status': 'pending',
      'decision_reason':
          'El aporte fue recibido y continuará procesándose en segundo plano.',
    };
  }

  Future<Map<String, dynamic>> completeProfile({
    required String evidenceId,
    required Map<String, dynamic> answers,
  }) async {
    return Map<String, dynamic>.from(
      await _api.post('/evidences/$evidenceId/profile', body: answers) as Map,
    );
  }

  Future<Map<String, dynamic>> _queueOffline({
    required File imageFile,
    required Map<String, dynamic> payload,
  }) async {
    final clientId = payload['client_evidence_id'].toString();
    final storedImage = await _persistImage(imageFile, clientId);
    final queued = <String, dynamic>{
      ...payload,
      'id': 'local-$clientId',
      'photo_local_path': storedImage.path,
      'status': 'offline_pending',
      'sync_status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'decision_reason':
          'Aporte guardado sin conexión. Se enviará automáticamente cuando recuperes internet.',
    };
    final queue = await _readQueue();
    queue.removeWhere(
      (item) => item['client_evidence_id']?.toString() == clientId,
    );
    queue.insert(0, queued);
    await _saveQueue(queue);
    return queued;
  }

  Future<int> syncPending() async {
    if (_syncInProgress ||
        Supabase.instance.client.auth.currentSession == null) {
      return 0;
    }
    _syncInProgress = true;
    try {
      final queue = await _readQueue();
      if (queue.isEmpty) return 0;
      final remaining = <Map<String, dynamic>>[];
      var synced = 0;
      for (final queued in queue) {
        if (queued['sync_status'] == 'failed') {
          remaining.add(queued);
          continue;
        }
        final imagePath = queued['photo_local_path']?.toString();
        final imageFile = imagePath == null ? null : File(imagePath);
        if (imageFile == null || !await imageFile.exists()) {
          remaining.add({
            ...queued,
            'status': 'failed',
            'sync_status': 'failed',
            'decision_reason':
                'La fotografía guardada ya no está disponible. Vuelve a realizar el aporte.',
          });
          continue;
        }

        final payload = Map<String, dynamic>.from(queued)
          ..remove('id')
          ..remove('photo_local_path')
          ..remove('status')
          ..remove('sync_status')
          ..remove('created_at')
          ..remove('decision_reason')
          ..remove('last_sync_error');
        try {
          await _send(imageFile: imageFile, payload: payload);
          await imageFile.delete();
          synced++;
        } on BackendApiException catch (error) {
          if (error.statusCode == 404 &&
              payload.containsKey('presence_sample_id')) {
            payload.remove('presence_sample_id');
            try {
              await _send(imageFile: imageFile, payload: payload);
              await imageFile.delete();
              synced++;
              continue;
            } on BackendApiException catch (retryError) {
              remaining.add({
                ...queued,
                if (!retryError.isNetworkFailure) ...{
                  'status': 'failed',
                  'sync_status': 'failed',
                  'decision_reason': friendlyErrorMessage(retryError),
                },
                'last_sync_error': friendlyErrorMessage(retryError),
              });
              if (retryError.isNetworkFailure) {
                final currentIndex = queue.indexOf(queued);
                remaining.addAll(queue.skip(currentIndex + 1));
                break;
              }
              continue;
            }
          }
          remaining.add({
            ...queued,
            if (!error.isNetworkFailure) ...{
              'status': 'failed',
              'sync_status': 'failed',
              'decision_reason': friendlyErrorMessage(error),
            },
            'last_sync_error': friendlyErrorMessage(error),
          });
          if (error.isNetworkFailure) {
            final currentIndex = queue.indexOf(queued);
            remaining.addAll(queue.skip(currentIndex + 1));
            break;
          }
        } catch (_) {
          remaining.add(queued);
        }
      }
      await _saveQueue(remaining);
      return synced;
    } finally {
      _syncInProgress = false;
    }
  }

  Future<List<Map<String, dynamic>>> pendingContributions() async {
    final queue = await _readQueue();
    return queue.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<int> retryPending(String clientEvidenceId) async {
    final queue = await _readQueue();
    var found = false;
    final updated = queue.map((item) {
      if (item['client_evidence_id']?.toString() != clientEvidenceId) {
        return item;
      }
      found = true;
      return <String, dynamic>{
        ...item,
        'status': 'offline_pending',
        'sync_status': 'pending',
        'decision_reason':
            'Aporte pendiente de conexión. Intentaremos enviarlo nuevamente.',
      }..remove('last_sync_error');
    }).toList();
    if (!found) return 0;
    await _saveQueue(updated);
    return syncPending();
  }

  Future<void> deletePending(String clientEvidenceId) async {
    final queue = await _readQueue();
    String? imagePath;
    queue.removeWhere((item) {
      final matches =
          item['client_evidence_id']?.toString() == clientEvidenceId;
      if (matches) imagePath = item['photo_local_path']?.toString();
      return matches;
    });
    await _saveQueue(queue);
    if (imagePath != null) {
      final image = File(imagePath!);
      if (await image.exists()) await image.delete();
    }
  }

  Future<List<Map<String, dynamic>>> obtenerReportesCercanos({
    required double latitud,
    required double longitud,
    double radio = 10000,
  }) async {
    final query = {'latitude': latitud, 'longitude': longitud, 'radius': radio};
    dynamic response;
    try {
      response = await _api.get('/places/community/nearby', query: query);
    } on BackendApiException catch (error) {
      if (error.statusCode != 404 &&
          error.statusCode != 502 &&
          error.statusCode != 503) {
        rethrow;
      }
      response = await _api.get('/evidences/nearby', query: query);
    }
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerMisAportes({int limit = 50}) async {
    await syncPending();
    final pending = await pendingContributions();
    try {
      final response = await _api.get('/evidences', query: {'limit': limit});
      final remote = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final remoteClientIds = remote
          .map((item) => item['client_evidence_id']?.toString())
          .whereType<String>()
          .toSet();
      final combined = [
        ...pending.where(
          (item) =>
              !remoteClientIds.contains(item['client_evidence_id']?.toString()),
        ),
        ...remote,
      ];
      combined.sort(
        (a, b) => (b['created_at']?.toString() ?? '').compareTo(
          a['created_at']?.toString() ?? '',
        ),
      );
      return combined;
    } on BackendApiException {
      if (pending.isNotEmpty) return pending;
      rethrow;
    }
  }

  Future<File> _persistImage(File source, String clientId) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      path.join(root.path, 'rutaamiga', 'pending_evidences'),
    );
    await directory.create(recursive: true);
    final extension = path.extension(source.path).toLowerCase();
    final target = File(
      path.join(
        directory.path,
        '$clientId${extension.isEmpty ? '.jpg' : extension}',
      ),
    );
    if (source.absolute.path == target.absolute.path) return source;
    return source.copy(target.path);
  }

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(preferences.getString(_queueKey) ?? '[]') as List;
      return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    final preferences = await SharedPreferences.getInstance();
    if (queue.isEmpty) {
      await preferences.remove(_queueKey);
      return;
    }
    await preferences.setString(_queueKey, jsonEncode(queue));
  }

  String _contentType(String filename) {
    final extension = path.extension(filename).toLowerCase();
    if (extension == '.png') return 'image/png';
    if (extension == '.webp') return 'image/webp';
    return 'image/jpeg';
  }
}
