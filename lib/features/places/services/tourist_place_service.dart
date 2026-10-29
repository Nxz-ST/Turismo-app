import '../../../core/network/backend_api_client.dart';
import '../models/tourist_place_model.dart';
import 'place_loader_service.dart';

class TouristPlaceService {
  final BackendApiClient _api = BackendApiClient();

  static const _verifiedCoordinateCorrections =
      <int, ({double latitude, double longitude, double altitude})>{
        11506: (latitude: -9.439077, longitude: -77.302956, altitude: 5721),
        11531: (latitude: -9.525, longitude: -77.385, altitude: 5434),
      };

  Future<List<Map<String, dynamic>>> obtenerLugaresCercanos({
    required double latitud,
    required double longitud,
    double radio = 10000,
  }) async {
    final localFuture = PlaceLoaderService.loadNearbyPlaces(
      latitude: latitud,
      longitude: longitud,
      radiusMeters: radio,
    );
    List<Map<String, dynamic>> remote = [];
    try {
      final response = await _api.get(
        '/places/nearby',
        query: {'latitude': latitud, 'longitude': longitud, 'radius': radio},
      );
      remote = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on BackendApiException catch (error) {
      if (error.statusCode == 401) rethrow;
    }

    final local = await localFuture;
    final merged = <String, Map<String, dynamic>>{};
    for (final row in remote) {
      final corrected = _applyVerifiedCoordinateCorrection(row);
      merged[_keyForRow(corrected)] = corrected;
    }
    for (final place in local) {
      merged.putIfAbsent(_keyForPlace(place), () => _toApiRow(place));
    }

    final results = _markSuspiciousCoordinateClusters(merged.values.toList());
    results.sort((a, b) {
      final distanceA = PlaceLoaderService.distanceMeters(
        latitud,
        longitud,
        double.tryParse(a['latitud'].toString()) ?? 0,
        double.tryParse(a['longitud'].toString()) ?? 0,
      );
      final distanceB = PlaceLoaderService.distanceMeters(
        latitud,
        longitud,
        double.tryParse(b['latitud'].toString()) ?? 0,
        double.tryParse(b['longitud'].toString()) ?? 0,
      );
      return distanceA.compareTo(distanceB);
    });
    return results;
  }

  String _keyForRow(Map<String, dynamic> row) {
    final code = int.tryParse(row['codigo']?.toString() ?? '') ?? 0;
    if (code > 0) return 'code:$code';
    return _nameKey(row['nombre']?.toString() ?? '');
  }

  Map<String, dynamic> _applyVerifiedCoordinateCorrection(
    Map<String, dynamic> row,
  ) {
    final code = int.tryParse(row['codigo']?.toString() ?? '') ?? 0;
    final correction = _verifiedCoordinateCorrections[code];
    if (correction == null) return row;
    return {
      ...row,
      'latitud': correction.latitude,
      'longitud': correction.longitude,
      'altitud': correction.altitude,
      'coordinate_quality': 'verified_correction',
    };
  }

  List<Map<String, dynamic>> _markSuspiciousCoordinateClusters(
    List<Map<String, dynamic>> rows,
  ) {
    final counts = <String, int>{};
    for (final row in rows) {
      final key = _coordinateKey(row);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return rows.map((row) {
      if ((counts[_coordinateKey(row)] ?? 0) < 3 ||
          row['coordinate_quality'] == 'verified_correction') {
        return row;
      }
      return {...row, 'coordinate_quality': 'approximate_cluster'};
    }).toList();
  }

  String _coordinateKey(Map<String, dynamic> row) {
    final latitude = double.tryParse(row['latitud']?.toString() ?? '') ?? 0;
    final longitude = double.tryParse(row['longitud']?.toString() ?? '') ?? 0;
    return '${latitude.toStringAsFixed(4)}|${longitude.toStringAsFixed(4)}';
  }

  String _keyForPlace(TouristPlaceModel place) {
    if (place.codigo > 0) return 'code:${place.codigo}';
    return _nameKey(place.nombre);
  }

  String _nameKey(String value) =>
      'name:${value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}';

  Map<String, dynamic> _toApiRow(TouristPlaceModel place) => {
    'id': place.id,
    'codigo': place.codigo,
    'nombre': place.nombre,
    'categoria_texto': place.categoria,
    'departamento': place.departamento,
    'provincia': place.provincia,
    'distrito': place.distrito,
    'latitud': place.latitud,
    'longitud': place.longitud,
    'altitud': place.altitud,
    'coordinate_quality': place.coordinateQuality,
    'access_latitud': place.accessLatitud,
    'access_longitud': place.accessLongitud,
    'access_notes': place.accessNotes,
    'descripcion': place.descripcion,
    'tipo_ingreso': place.tipoIngreso,
    'tarifa_adulto': place.tarifaAdulto,
    'tarifa_nino': place.tarifaNino,
    'tarifa_extranjero': place.tarifaExtranjero,
    'epoca_visita': place.epocaVisita,
    'horario_visita': place.horarioVisita,
    'recomendaciones_visita': place.recomendacionesVisita,
    'actividades': place.actividades,
    'source': 'mincetur_offline_catalog',
  };
}
