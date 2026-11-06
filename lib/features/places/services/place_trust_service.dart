import '../../../core/network/backend_api_client.dart';
import '../models/place_trust_model.dart';

class PlaceTrustService {
  final BackendApiClient _api = BackendApiClient();

  Future<PlaceTrustModel> getPassport({
    required String source,
    required String placeId,
  }) async {
    final response = await _api.get('/places/$source/$placeId/trust');
    return PlaceTrustModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>> getCommunityPlace(String placeId) async {
    return Map<String, dynamic>.from(
      await _api.get('/places/community/$placeId') as Map,
    );
  }

  Future<void> reportPlaceIssue({
    required String source,
    required String placeId,
    required String placeName,
    required String issueType,
    required String details,
  }) async {
    await _api.post(
      '/places/$source/$placeId/reports',
      body: {
        'place_name': placeName,
        'issue_type': issueType,
        'details': details.trim(),
        'observed_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
