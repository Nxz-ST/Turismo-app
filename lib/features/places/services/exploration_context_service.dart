import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/backend_api_client.dart';

class ExplorationArea {
  const ExplorationArea({
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.scope = 'Alrededores',
    this.usesDeviceLocation = false,
  });

  final String name;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String scope;
  final bool usesDeviceLocation;

  double get radius => switch (scope) {
    'Ciudad' => 15000,
    'Región' => 100000,
    _ => 40000,
  };

  ExplorationArea copyWith({String? scope}) => ExplorationArea(
    name: name,
    subtitle: subtitle,
    latitude: latitude,
    longitude: longitude,
    scope: scope ?? this.scope,
    usesDeviceLocation: usesDeviceLocation,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'subtitle': subtitle,
    'latitude': latitude,
    'longitude': longitude,
    'scope': scope,
    'uses_device_location': usesDeviceLocation,
  };

  factory ExplorationArea.fromJson(Map<String, dynamic> json) =>
      ExplorationArea(
        name: json['name']?.toString() ?? 'Destino',
        subtitle: json['subtitle']?.toString() ?? 'Perú',
        latitude: double.tryParse(json['latitude'].toString()) ?? 0,
        longitude: double.tryParse(json['longitude'].toString()) ?? 0,
        scope: json['scope']?.toString() ?? 'Alrededores',
        usesDeviceLocation: json['uses_device_location'] == true,
      );
}

class ExplorationContextService extends ChangeNotifier {
  ExplorationContextService._();

  static final instance = ExplorationContextService._();
  static const _storageKey = 'rutaamiga_exploration_area_v1';
  final BackendApiClient _api = BackendApiClient();

  ExplorationArea? _area;
  ExplorationArea? get area => _area;
  bool get isRemote => _area != null && !_area!.usesDeviceLocation;

  Future<void> restore() async {
    if (_area != null) return;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return;
    try {
      _area = ExplorationArea.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      await preferences.remove(_storageKey);
    }
  }

  Future<void> select(ExplorationArea area) async {
    _area = area;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(area.toJson()));
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    _area = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    notifyListeners();
  }

  Future<List<ExplorationArea>> search(String query) async {
    if (query.trim().length < 2) return [];
    final response = await _api.get(
      '/maps/destinations/search',
      query: {'query': query.trim()},
    );
    return (response as List)
        .map((item) {
          final data = Map<String, dynamic>.from(item as Map);
          return ExplorationArea(
            name: data['name']?.toString() ?? query,
            subtitle: data['address']?.toString() ?? 'Perú',
            latitude: double.tryParse(data['latitude'].toString()) ?? 0,
            longitude: double.tryParse(data['longitude'].toString()) ?? 0,
          );
        })
        .where((area) => area.latitude != 0 && area.longitude != 0)
        .toList();
  }
}
