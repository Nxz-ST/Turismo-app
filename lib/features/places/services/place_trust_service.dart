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
}
