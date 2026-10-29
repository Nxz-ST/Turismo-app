import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../models/tourist_place_model.dart';

class PlaceLoaderService {
  static List<TouristPlaceModel>? _cache;

  static Future<List<TouristPlaceModel>> loadPlaces() async {
    if (_cache != null) return _cache!;
    final String response = await rootBundle.loadString(
      'assets/data/lugares_turisticos.json',
    );
    final List<dynamic> data = json.decode(response);
    final loaded = data
        .map(
          (item) => TouristPlaceModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where(
          (place) =>
              place.latitud >= -90 &&
              place.latitud <= 90 &&
              place.longitud >= -180 &&
              place.longitud <= 180 &&
              place.latitud != 0 &&
              place.longitud != 0,
        )
        .toList(growable: false);
    final coordinateCounts = <String, int>{};
    for (final place in loaded) {
      final key = _coordinateKey(place.latitud, place.longitud);
      coordinateCounts[key] = (coordinateCounts[key] ?? 0) + 1;
    }
    _cache = loaded
        .map((place) {
          final count =
              coordinateCounts[_coordinateKey(place.latitud, place.longitud)] ??
              0;
          if (count >= 3 && place.coordinateQuality != 'verified_correction') {
            return place.copyWith(coordinateQuality: 'approximate_cluster');
          }
          return place;
        })
        .toList(growable: false);
    return _cache!;
  }

  static Future<List<TouristPlaceModel>> loadNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final places = await loadPlaces();
    final nearby = places.where((place) {
      return distanceMeters(
            latitude,
            longitude,
            place.latitud,
            place.longitud,
          ) <=
          radiusMeters;
    }).toList();
    nearby.sort(
      (a, b) => distanceMeters(
        latitude,
        longitude,
        a.latitud,
        a.longitud,
      ).compareTo(distanceMeters(latitude, longitude, b.latitud, b.longitud)),
    );
    return nearby;
  }

  static double distanceMeters(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadius = 6371000.0;
    final latitudeDelta = _radians(latitudeB - latitudeA);
    final longitudeDelta = _radians(longitudeB - longitudeA);
    final a =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(_radians(latitudeA)) *
            math.cos(_radians(latitudeB)) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  static String _coordinateKey(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(4)}|${longitude.toStringAsFixed(4)}';
}
