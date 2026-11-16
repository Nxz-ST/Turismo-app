import '../../../core/network/backend_api_client.dart';
import '../models/tourism_benefit.dart';

class BenefitApiService {
  final BackendApiClient _api = BackendApiClient();

  Future<List<TourismBenefit>> forPlace({
    required String placeKey,
    required String placeName,
  }) async {
    final target = _target(placeKey);
    final response = await _api.get(
      '/benefits/places/${target.source}/${target.id}',
      query: {'place_name': placeName},
    );
    return (response as List)
        .map(
          (item) =>
              TourismBenefit.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<BenefitPass?> activePass(String placeKey, String benefitId) async {
    final target = _target(placeKey);
    final response = await _api.get('/benefits/me/redemptions');
    for (final item in response as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final benefit = Map<String, dynamic>.from(
        row['benefit'] as Map? ?? const {},
      );
      if (benefit['id']?.toString() == benefitId &&
          row['place_source']?.toString() == target.source &&
          row['place_id']?.toString() == target.id) {
        return _pass(row);
      }
    }
    return null;
  }

  Future<BenefitPass> claim({
    required String placeKey,
    required String placeName,
    required String benefitId,
  }) async {
    final target = _target(placeKey);
    final response = Map<String, dynamic>.from(
      await _api.post(
            '/benefits/$benefitId/claim',
            body: {
              'place_source': target.source,
              'place_id': target.id,
              'place_name': placeName,
            },
          )
          as Map,
    );
    return _pass(response);
  }

  BenefitPass _pass(Map<String, dynamic> row) => BenefitPass(
    id: row['id']?.toString(),
    code: row['code'].toString(),
    status: row['status']?.toString() ?? 'requested',
    activatedAt: DateTime.parse(row['created_at'].toString()).toLocal(),
    expiresAt: DateTime.parse(row['expires_at'].toString()).toLocal(),
  );

  ({String source, String id}) _target(String placeKey) {
    if (placeKey.startsWith('community_')) {
      return (source: 'community', id: placeKey.substring('community_'.length));
    }
    return (source: 'official', id: placeKey.replaceFirst('official_', ''));
  }
}
