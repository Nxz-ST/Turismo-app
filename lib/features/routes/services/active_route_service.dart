import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveRouteService extends ChangeNotifier {
  ActiveRouteService._();

  static final ActiveRouteService instance = ActiveRouteService._();
  static const _storageKey = 'active_route_session_v1';

  Map<String, dynamic>? _route;
  DateTime? _startedAt;
  bool _restored = false;

  Map<String, dynamic>? get route => _route;
  DateTime? get startedAt => _startedAt;
  bool get hasActiveRoute => _route != null;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final payload = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _route = Map<String, dynamic>.from(payload['route'] as Map);
      _startedAt = DateTime.tryParse(payload['started_at']?.toString() ?? '');
      notifyListeners();
    } catch (_) {
      await preferences.remove(_storageKey);
    }
  }

  Future<void> start(Map<String, dynamic> route) async {
    _route = Map<String, dynamic>.from(route);
    _startedAt = DateTime.now();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'route': _route,
        'started_at': _startedAt!.toIso8601String(),
      }),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    _route = null;
    _startedAt = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    notifyListeners();
  }

  bool matches(Map<String, dynamic> candidate) {
    final active = _route;
    if (active == null) return false;
    return routeKey(active) == routeKey(candidate);
  }

  static String routeKey(Map<String, dynamic> route) {
    final routeId = route['id']?.toString() ?? 'suggested';
    final stops = (route['stops'] as List? ?? const []);
    final stopIds = stops
        .map((stop) => (stop as Map)['id']?.toString() ?? '')
        .join('-');
    return '${routeId}_$stopIds';
  }

  static String progressKey(Map<String, dynamic> route) =>
      'route_progress_${routeKey(route)}';
}
