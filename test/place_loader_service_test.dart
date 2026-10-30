import 'package:flutter_test/flutter_test.dart';
import 'package:turismo_app/features/places/models/tourist_place_model.dart';
import 'package:turismo_app/features/places/services/place_loader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el catálogo offline contiene atractivos alrededor de Huaraz', () async {
    final places = await PlaceLoaderService.loadNearbyPlaces(
      latitude: -9.52945,
      longitude: -77.52916,
      radiusMeters: 100000,
    );

    expect(places.length, greaterThan(2));
    expect(
      places.any((place) => place.provincia.toLowerCase() == 'huaraz'),
      isTrue,
    );
    expect(places.every((place) => place.id != 0), isTrue);

    final cayesh = places.singleWhere((place) => place.codigo == 11506);
    expect(cayesh.latitud, closeTo(-9.463956834814669, 0.000001));
    expect(cayesh.longitud, closeTo(-77.31155206387554, 0.000001));
    expect(cayesh.altitud, 5721);
    expect(cayesh.coordinateQuality, 'verified_correction');
    expect(
      PlaceLoaderService.distanceMeters(
        -9.52945,
        -77.52916,
        cayesh.latitud,
        cayesh.longitud,
      ),
      greaterThan(20000),
    );
  });

  test(
    'el catálogo auditado elimina coordenadas masivamente repetidas',
    () async {
      final places = await PlaceLoaderService.loadPlaces();
      final approximate = places
          .where((place) => place.coordinateQuality == 'approximate_cluster')
          .toList();

      expect(places.length, 530);
      expect(approximate, isEmpty);
      expect(
        places.every(
          (place) => place.coordinateQuality == 'verified_correction',
        ),
        isTrue,
      );

      final timon = places.singleWhere((place) => place.codigo == 1754);
      expect(timon.latitud, closeTo(-7.449139960880176, 0.000001));
      expect(timon.longitud, closeTo(-76.90192676225385, 0.000001));
      expect(timon.altitud, 320);
    },
  );

  test('usa el acceso aprobado solo para navegación', () {
    final place = TouristPlaceModel.fromSupabase({
      'id': 1,
      'codigo': 1,
      'nombre': 'Nevado de prueba',
      'categoria_texto': 'Sitio natural',
      'departamento': 'Áncash',
      'provincia': 'Huaraz',
      'distrito': 'Huaraz',
      'latitud': -9.4,
      'longitud': -77.3,
      'altitud': 5500,
      'access_latitud': -9.45,
      'access_longitud': -77.35,
      'access_notes': 'Inicio del sendero',
    });

    expect(place.latitud, -9.4);
    expect(place.navigationLatitud, -9.45);
    expect(place.navigationLongitud, -77.35);
    expect(place.hasVerifiedAccess, isTrue);
    expect(place.toStorageJson()['access_notes'], 'Inicio del sendero');
  });
}
