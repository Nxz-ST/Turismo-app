import 'tourist_place_model.dart';

class ExistingPlaceTarget {
  const ExistingPlaceTarget({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.source,
    this.district = '',
    this.province = '',
    this.photoUrl,
  });

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String source;
  final String district;
  final String province;
  final String? photoUrl;

  bool get isCommunity => source == 'community';

  factory ExistingPlaceTarget.fromOfficial(TouristPlaceModel place) =>
      ExistingPlaceTarget(
        id: place.id.toString(),
        name: place.nombre,
        category: place.categoria,
        latitude: place.latitud,
        longitude: place.longitud,
        source: 'official',
        district: place.distrito,
        province: place.provincia,
      );

  factory ExistingPlaceTarget.fromCommunity(Map<String, dynamic> row) =>
      ExistingPlaceTarget(
        id: row['id'].toString(),
        name: row['nombre']?.toString() ?? 'Descubrimiento comunitario',
        category: row['categoria_ia']?.toString() ?? 'Lugar natural',
        latitude: double.tryParse(row['latitud']?.toString() ?? '') ?? 0,
        longitude: double.tryParse(row['longitud']?.toString() ?? '') ?? 0,
        source: 'community',
        photoUrl: row['foto_url']?.toString(),
      );
}
