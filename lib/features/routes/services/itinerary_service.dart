import '../../../core/network/backend_api_client.dart';

class ItineraryService {
  final BackendApiClient _api = BackendApiClient();

  Future<List<Map<String, dynamic>>> suggestions({
    required double latitude,
    required double longitude,
    double radius = 30000,
    int durationMinutes = 300,
    String experience = 'mixed',
    String travelMode = 'driving',
    String intent = 'nearby',
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationName,
    int maxDetourMinutes = 20,
  }) async {
    final response = await _api.get(
      '/itineraries/suggestions',
      query: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'duration_minutes': durationMinutes,
        'experience': experience,
        'travel_mode': travelMode,
        'intent': intent,
        if (destinationLatitude != null)
          'destination_latitude': destinationLatitude,
        if (destinationLongitude != null)
          'destination_longitude': destinationLongitude,
        if (destinationName != null) 'destination_name': destinationName,
        'max_detour_minutes': maxDetourMinutes,
      },
    );
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
