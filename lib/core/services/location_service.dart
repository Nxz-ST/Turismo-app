import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _cachedPosition;
  static DateTime? _cachedAt;

  static Future<Position> getCurrentLocation() async {
    final cached = _cachedPosition;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(minutes: 2)) {
      return cached;
    }

    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si GPS está activo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('GPS desactivado');
    }

    // Verifica permisos
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Permiso denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permisos bloqueados');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _remember(position);
      return position;
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _remember(lastKnown);
        return lastKnown;
      }
      rethrow;
    }
  }

  static void _remember(Position position) {
    _cachedPosition = position;
    _cachedAt = DateTime.now();
  }
}
