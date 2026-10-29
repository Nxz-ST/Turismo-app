import '../../../core/network/backend_api_client.dart';

class TouristGalleryPhoto {
  const TouristGalleryPhoto({
    required this.id,
    required this.source,
    required this.attribution,
    required this.thumbnailUrl,
    required this.largeUrl,
    required this.requiresAuthentication,
  });

  final String id;
  final String source;
  final String attribution;
  final String thumbnailUrl;
  final String largeUrl;
  final bool requiresAuthentication;

  bool get isCommunity => source == 'community';
}

class GooglePlacesService {
  final BackendApiClient _api = BackendApiClient();
  final Map<String, Future<String?>> _touristPhotoCache = {};

  Map<String, String> get photoHeaders => _api.authenticatedImageHeaders;

  Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double lat,
    required double lng,
    required String type,
    double radius = 1500,
  }) async {
    final response = await _api.get(
      '/maps/services/nearby',
      query: {
        'latitude': lat,
        'longitude': lng,
        'type': type,
        'radius': radius,
      },
    );
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  String? getPhotoUrl(Map<String, dynamic> place) {
    final photos = place['photos'];
    if (photos is! List || photos.isEmpty) return null;
    final first = photos.first;
    if (first is! Map || first['name'] == null) return null;
    return _photoMediaUrl(first['name'].toString(), 400, 400);
  }

  Future<String?> getTouristPhotoUrl({
    required String name,
    required double lat,
    required double lng,
  }) async {
    final cacheKey =
        '$name|${lat.toStringAsFixed(4)}|${lng.toStringAsFixed(4)}';
    final cached = _touristPhotoCache[cacheKey];
    if (cached != null) return cached;

    final request = _fetchTouristPhotoUrl(name: name, lat: lat, lng: lng);
    _touristPhotoCache[cacheKey] = request;
    final result = await request;
    // Un resultado vacío puede ser transitorio (red, sesión o cuota). No debe
    // quedar cacheado durante toda la vida de la app.
    if (result == null) _touristPhotoCache.remove(cacheKey);
    return result;
  }

  Future<String?> _fetchTouristPhotoUrl({
    required String name,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _api.get(
        '/maps/photos/tourist',
        query: {'name': name, 'latitude': lat, 'longitude': lng},
      );
      final photoName = (response as Map)['photo_name']?.toString();
      if (photoName == null || photoName.isEmpty) return null;
      return _photoMediaUrl(photoName, 800, 600);
    } on BackendApiException {
      // La foto es opcional. El backend ya controla cuotas y errores del
      // proveedor; una falla aislada no debe desactivar todas las miniaturas.
      return null;
    }
  }

  Future<List<TouristGalleryPhoto>> getTouristGallery({
    required String name,
    required double lat,
    required double lng,
    int limit = 10,
  }) {
    return _fetchTouristGallery(name: name, lat: lat, lng: lng, limit: limit);
  }

  Future<List<TouristGalleryPhoto>> _fetchTouristGallery({
    required String name,
    required double lat,
    required double lng,
    required int limit,
  }) async {
    try {
      final response = await _api.get(
        '/maps/photos/gallery',
        query: {
          'name': name,
          'latitude': lat,
          'longitude': lng,
          'limit': limit,
        },
      );
      return (response as List)
          .map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            final source = item['source']?.toString() ?? 'google';
            final directUrl = item['url']?.toString();
            final photoName = item['photo_name']?.toString();
            final usesBackendMedia = source == 'google' && photoName != null;
            final thumbnailUrl = usesBackendMedia
                ? _photoMediaUrl(photoName, 720, 540)
                : directUrl ?? '';
            final largeUrl = usesBackendMedia
                ? _photoMediaUrl(photoName, 1440, 1200)
                : directUrl ?? '';
            return TouristGalleryPhoto(
              id: item['id']?.toString() ?? thumbnailUrl,
              source: source,
              attribution: item['attribution']?.toString() ?? 'RutaAmiga',
              thumbnailUrl: thumbnailUrl,
              largeUrl: largeUrl,
              requiresAuthentication: usesBackendMedia,
            );
          })
          .where((photo) => photo.thumbnailUrl.isNotEmpty)
          .toList();
    } on BackendApiException {
      return const [];
    }
  }

  Map<String, String>? headersFor(TouristGalleryPhoto photo) =>
      photo.requiresAuthentication ? photoHeaders : null;

  String _photoMediaUrl(String photoName, int width, int height) {
    return _api.uri('/maps/photos/media', {
      'name': photoName,
      'max_width': width,
      'max_height': height,
    }).toString();
  }
}
