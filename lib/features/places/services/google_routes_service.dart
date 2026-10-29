import '../../../core/network/backend_api_client.dart';

class GoogleRoutesService {
  final BackendApiClient _api = BackendApiClient();

  Future<Map<String, dynamic>> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'driving',
  }) async {
    final response = await _api.post(
      '/maps/routes',
      body: {
        'origin_latitude': originLat,
        'origin_longitude': originLng,
        'destination_latitude': destinationLat,
        'destination_longitude': destinationLng,
        'travel_mode': travelMode,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
