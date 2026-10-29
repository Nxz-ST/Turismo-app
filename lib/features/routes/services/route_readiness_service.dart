class RouteReadiness {
  const RouteReadiness({
    required this.minAltitudeMeters,
    required this.maxAltitudeMeters,
    required this.elevationSpanMeters,
    required this.difficulty,
    required this.difficultyReason,
    required this.items,
    required this.alerts,
    required this.sources,
  });

  final int minAltitudeMeters;
  final int maxAltitudeMeters;
  final int elevationSpanMeters;
  final String difficulty;
  final String difficultyReason;
  final List<String> items;
  final List<String> alerts;
  final List<RouteInformationSource> sources;
}

class RouteInformationSource {
  const RouteInformationSource({
    required this.label,
    required this.detail,
    required this.kind,
  });

  final String label;
  final String detail;
  final String kind;
}

class RouteReadinessService {
  const RouteReadinessService();

  RouteReadiness evaluate({
    required List<Map<String, dynamic>> stops,
    Map<String, dynamic>? weather,
    int routeDurationMinutes = 0,
    double routeDistanceKm = 0,
    bool hasRoadRoute = false,
  }) {
    var maxAltitude = 0;
    int? minAltitude;
    var difficultyScore = 0;
    var hasWater = false;
    var hasMountain = false;
    var approximateCoordinates = false;
    var hasOfficial = false;
    var hasCommunity = false;
    for (final stop in stops) {
      final altitude = (stop['altitude_m'] as num?)?.round() ?? 0;
      if (altitude > 0) {
        if (altitude > maxAltitude) maxAltitude = altitude;
        minAltitude = minAltitude == null
            ? altitude
            : altitude < minAltitude
            ? altitude
            : minAltitude;
      }
      final text = '${stop['name']} ${stop['category']} ${stop['activities']}'
          .toLowerCase();
      hasWater =
          hasWater ||
          _contains(text, const [
            'playa',
            'lago',
            'laguna',
            'cascada',
            'río',
            'rio',
          ]);
      hasMountain =
          hasMountain ||
          _contains(text, const [
            'nevado',
            'montaña',
            'montana',
            'trekking',
            'senderismo',
          ]);
      final difficulty = stop['difficulty']?.toString().toLowerCase() ?? '';
      if (difficulty.contains('exigente')) {
        difficultyScore += 3;
      } else if (difficulty.contains('alta')) {
        difficultyScore += 2;
      } else if (difficulty.contains('moderada') ||
          difficulty.contains('media')) {
        difficultyScore += 1;
      }
      if (text.contains('nevado') || text.contains('glaciar')) {
        difficultyScore += 3;
      } else if (text.contains('trekking') || text.contains('senderismo')) {
        difficultyScore += 1;
      }
      approximateCoordinates =
          approximateCoordinates ||
          stop['coordinate_quality'] == 'approximate_cluster';
      hasOfficial = hasOfficial || stop['source'] == 'official';
      hasCommunity = hasCommunity || stop['source'] == 'community';
    }

    final minimum = minAltitude ?? 0;
    final elevationSpan = maxAltitude > 0 ? maxAltitude - minimum : 0;
    if (maxAltitude >= 4500) {
      difficultyScore += 3;
    } else if (maxAltitude >= 3000) {
      difficultyScore += 2;
    } else if (maxAltitude >= 2500) {
      difficultyScore += 1;
    }
    if (elevationSpan >= 800) {
      difficultyScore += 2;
    } else if (elevationSpan >= 300) {
      difficultyScore += 1;
    }
    if (routeDurationMinutes >= 480) {
      difficultyScore += 2;
    } else if (routeDurationMinutes >= 240) {
      difficultyScore += 1;
    }
    if (routeDistanceKm >= 80) difficultyScore += 1;

    final current = Map<String, dynamic>.from(
      weather?['current'] as Map? ?? const {},
    );
    final daily = Map<String, dynamic>.from(
      weather?['daily'] as Map? ?? const {},
    );
    final rainProbability = _firstNumber(
      daily['precipitation_probability_max'],
    );
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;
    final apparent = (current['apparent_temperature'] as num?)?.toDouble();

    final items = <String>{
      'Agua y documento personal',
      'Protector solar',
      if (hasWater) 'Ropa de cambio y bolsa impermeable',
      if (hasMountain || maxAltitude >= 2500) 'Calzado con buen agarre',
      if (maxAltitude >= 3000 || (apparent != null && apparent < 12))
        'Abrigo por capas',
      if (rainProbability >= 40) 'Impermeable ligero',
    };
    final alerts = <String>[
      if (maxAltitude >= 3000)
        'Altitud elevada: aclimátate, avanza despacio y evita esfuerzo si presentas síntomas.',
      if (rainProbability >= 50)
        'Hay probabilidad de lluvia; verifica accesos antes de salir.',
      if (wind >= 35)
        'Se esperan vientos fuertes, especialmente sensibles en miradores y montaña.',
      if (difficultyScore >= 6)
        'La ruta incluye una actividad exigente; considera guía local y salida temprana.',
      if (approximateCoordinates)
        'Una parada tiene ubicación referencial y no debe usarse como destino exacto.',
    ];
    final difficulty = difficultyScore >= 6
        ? 'Exigente'
        : difficultyScore >= 3
        ? 'Moderada'
        : 'Ligera';
    final reasons = <String>[
      if (maxAltitude >= 3000) 'altitud',
      if (elevationSpan >= 300) 'desnivel entre paradas',
      if (hasMountain) 'actividad de montaña',
      if (routeDurationMinutes >= 240) 'duración del plan',
      if (routeDistanceKm >= 80) 'distancia vial',
    ];
    final sources = <RouteInformationSource>[
      if (hasOfficial)
        const RouteInformationSource(
          label: 'Lugares',
          detail: 'Registro turístico oficial',
          kind: 'official',
        ),
      if (hasCommunity)
        const RouteInformationSource(
          label: 'Descubrimientos',
          detail: 'Comunidad validada',
          kind: 'community',
        ),
      if (weather != null)
        RouteInformationSource(
          label: 'Clima',
          detail: weather['source']?.toString() ?? 'Open-Meteo',
          kind: 'live',
        ),
      RouteInformationSource(
        label: 'Trayecto',
        detail: hasRoadRoute ? 'Google Routes' : 'Estimación geográfica',
        kind: hasRoadRoute ? 'live' : 'estimate',
      ),
      const RouteInformationSource(
        label: 'Dificultad',
        detail: 'Estimación RutaAmiga',
        kind: 'estimate',
      ),
    ];
    return RouteReadiness(
      minAltitudeMeters: minimum,
      maxAltitudeMeters: maxAltitude,
      elevationSpanMeters: elevationSpan,
      difficulty: difficulty,
      difficultyReason: reasons.isEmpty
          ? 'Basada en el tipo de visita y los datos disponibles.'
          : 'Calculada por ${reasons.join(', ')}.',
      items: items.toList(),
      alerts: alerts,
      sources: sources,
    );
  }

  static bool _contains(String value, List<String> words) =>
      words.any(value.contains);

  static double _firstNumber(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return double.tryParse(value.first.toString()) ?? 0;
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
