import 'package:flutter_test/flutter_test.dart';
import 'package:turismo_app/features/routes/services/route_readiness_service.dart';

void main() {
  const service = RouteReadinessService();

  test('prepara una salida de playa con equipamiento ligero', () {
    final readiness = service.evaluate(
      stops: const [
        {
          'name': 'Playa Tuquillo',
          'category': 'Playa',
          'difficulty': 'baja',
          'altitude_m': 5,
        },
      ],
    );

    expect(readiness.difficulty, 'Ligera');
    expect(readiness.items, contains('Ropa de cambio y bolsa impermeable'));
    expect(readiness.alerts, isEmpty);
  });

  test('advierte la altitud y exigencia de un nevado', () {
    final readiness = service.evaluate(
      stops: const [
        {
          'name': 'Nevado Vallunaraju',
          'category': 'Sitio natural',
          'difficulty': 'alta',
          'altitude_m': 5686,
        },
      ],
    );

    expect(readiness.difficulty, 'Exigente');
    expect(readiness.maxAltitudeMeters, 5686);
    expect(readiness.items, contains('Abrigo por capas'));
    expect(readiness.items, contains('Calzado con buen agarre'));
    expect(readiness.alerts.any((alert) => alert.contains('Altitud')), isTrue);
    expect(
      readiness.alerts.any((alert) => alert.contains('guía local')),
      isTrue,
    );
  });

  test('incorpora lluvia y viento del pronóstico', () {
    final readiness = service.evaluate(
      stops: const [
        {'name': 'Mirador', 'category': 'Mirador', 'altitude_m': 400},
      ],
      weather: const {
        'current': {'wind_speed_10m': 42, 'apparent_temperature': 8},
        'daily': {
          'precipitation_probability_max': [70],
        },
      },
    );

    expect(readiness.items, contains('Impermeable ligero'));
    expect(readiness.items, contains('Abrigo por capas'));
    expect(readiness.alerts.any((alert) => alert.contains('lluvia')), isTrue);
    expect(readiness.alerts.any((alert) => alert.contains('vientos')), isTrue);
  });

  test('no permite tratar una coordenada referencial como exacta', () {
    final readiness = service.evaluate(
      stops: const [
        {
          'name': 'Lugar referencial',
          'category': 'Sitio natural',
          'coordinate_quality': 'approximate_cluster',
        },
      ],
    );

    expect(
      readiness.alerts.any((alert) => alert.contains('ubicación referencial')),
      isTrue,
    );
  });

  test('calcula dificultad usando desnivel, duración y distancia', () {
    final readiness = service.evaluate(
      stops: const [
        {
          'name': 'Inicio de sendero',
          'category': 'Trekking',
          'altitude_m': 2800,
          'source': 'official',
        },
        {
          'name': 'Mirador alto',
          'category': 'Montaña',
          'altitude_m': 3800,
          'source': 'official',
        },
      ],
      routeDurationMinutes: 500,
      routeDistanceKm: 90,
      hasRoadRoute: true,
    );

    expect(readiness.elevationSpanMeters, 1000);
    expect(readiness.difficulty, 'Exigente');
    expect(readiness.difficultyReason, contains('desnivel'));
    expect(
      readiness.sources.any(
        (source) =>
            source.label == 'Trayecto' && source.detail == 'Google Routes',
      ),
      isTrue,
    );
    expect(
      readiness.sources.any(
        (source) => source.detail == 'Estimación RutaAmiga',
      ),
      isTrue,
    );
  });
}
