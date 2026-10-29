import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../network/backend_api_client.dart';
import 'location_service.dart';

class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  static const _deviceKey = 'presence_device_id';
  static const _queueKey = 'presence_pending_samples';
  static const _lastSampleKey = 'presence_last_sample_at';

  final BackendApiClient _api = BackendApiClient();

  Future<Map<String, dynamic>?> record({
    required String source,
    bool force = false,
  }) async {
    if (Supabase.instance.client.auth.currentSession == null) return null;
    final position = await LocationService.getCurrentLocation();
    return recordPosition(position, source: source, force: force);
  }

  Future<Map<String, dynamic>?> recordPosition(
    Position position, {
    required String source,
    bool force = false,
  }) async {
    if (Supabase.instance.client.auth.currentSession == null) return null;
    final preferences = await SharedPreferences.getInstance();
    final enabled =
        preferences.getBool('rutaamiga_presence_support_v1') ?? true;
    if (!enabled) return null;
    final previous = DateTime.tryParse(
      preferences.getString(_lastSampleKey) ?? '',
    );
    if (!force &&
        previous != null &&
        DateTime.now().difference(previous) < const Duration(minutes: 5)) {
      await syncPending();
      return null;
    }

    var deviceId = preferences.getString(_deviceKey);
    deviceId ??= const Uuid().v4();
    await preferences.setString(_deviceKey, deviceId);
    final sample = <String, dynamic>{
      'client_sample_id': const Uuid().v4(),
      'device_id': deviceId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'accuracy_m': position.accuracy,
      'recorded_at': position.timestamp.toUtc().toIso8601String(),
      'source': source,
      'is_mocked': position.isMocked,
    };
    final queue = _readQueue(preferences)..add(sample);
    await preferences.setString(_queueKey, jsonEncode(queue));
    await preferences.setString(
      _lastSampleKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    final synced = await syncPending();
    return synced
        .where((row) => row['client_sample_id'] == sample['client_sample_id'])
        .firstOrNull;
  }

  Future<List<Map<String, dynamic>>> syncPending() async {
    if (Supabase.instance.client.auth.currentSession == null) return const [];
    final preferences = await SharedPreferences.getInstance();
    final queue = _readQueue(preferences);
    if (queue.isEmpty) return const [];
    try {
      final response = await _api.post(
        '/presence/samples',
        body: {'samples': queue},
      );
      final rows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      await preferences.remove(_queueKey);
      return rows;
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> recent({int limit = 30}) async {
    await syncPending();
    final response = await _api.get(
      '/presence/recent',
      query: {'limit': limit},
    );
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  List<Map<String, dynamic>> _readQueue(SharedPreferences preferences) {
    try {
      final raw = jsonDecode(preferences.getString(_queueKey) ?? '[]') as List;
      return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
