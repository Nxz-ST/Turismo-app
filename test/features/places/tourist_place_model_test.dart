import 'package:flutter_test/flutter_test.dart';
import 'package:turismo_app/features/places/models/tourist_place_model.dart';

void main() {
  group('TouristPlaceModel community support', () {
    const communityId = 'bd92fdfb-7699-4fb4-b20a-2811327df448';
    final source = <String, dynamic>{
      'id': communityId,
      'nombre': 'cascada arampampa',
      'categoria_ia': 'cascada',
      'latitud': -11.99,
      'longitud': -76.83,
      'descripcion': 'Descubrimiento corroborado.',
    };

    test('creates a stable community identity', () {
      final first = TouristPlaceModel.fromCommunity(source);
      final second = TouristPlaceModel.fromCommunity(source);

      expect(first.id, isNegative);
      expect(first.id, second.id);
      expect(first.source, 'community');
      expect(first.communityId, communityId);
      expect(first.libraryKey, 'community-$communityId');
    });

    test('keeps community identity after local persistence', () {
      final original = TouristPlaceModel.fromCommunity(source);
      final restored = TouristPlaceModel.fromStorage(original.toStorageJson());

      expect(restored.libraryKey, original.libraryKey);
      expect(restored.nombre, original.nombre);
      expect(restored.latitud, original.latitud);
      expect(restored.longitud, original.longitud);
    });

    test('official places preserve their original identity', () {
      final official = TouristPlaceModel.fromStorage({
        'id': 42,
        'codigo': 100,
        'nombre': 'Lugar oficial',
      });

      expect(official.source, 'official');
      expect(official.communityId, isNull);
      expect(official.libraryKey, 'official-42');
    });
  });
}
