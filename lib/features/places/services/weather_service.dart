import '../../../core/network/backend_api_client.dart';

class WeatherService {
  final BackendApiClient _api = BackendApiClient();

  Future<Map<String, dynamic>> forecast({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.get(
      '/weather/forecast',
      query: {'latitude': latitude, 'longitude': longitude},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
