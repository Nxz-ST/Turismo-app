import '../../../core/network/backend_api_client.dart';

class AdminReviewService {
  final BackendApiClient _api = BackendApiClient();

  Future<List<Map<String, dynamic>>> queue() async {
    final response = await _api.get('/admin/reviews');
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> decide({
    required String evidenceId,
    required String status,
    required String reason,
    String? category,
  }) async {
    return Map<String, dynamic>.from(
      await _api.patch(
            '/admin/reviews/$evidenceId',
            body: {
              'status': status,
              'reason': reason,
              if (category != null) 'category': category,
            },
          )
          as Map,
    );
  }

  Future<List<Map<String, dynamic>>> coordinateQueue() async {
    final response = await _api.get('/admin/coordinate-reviews');
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> coordinateSuggestions(
    String reviewId,
  ) async {
    final response = await _api.get(
      '/admin/coordinate-reviews/$reviewId/suggestions',
    );
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> decideCoordinate({
    required String reviewId,
    required String action,
    required String note,
    Map<String, dynamic>? candidate,
  }) async {
    return Map<String, dynamic>.from(
      await _api.patch(
            '/admin/coordinate-reviews/$reviewId',
            body: {
              'action': action,
              'note': note,
              if (candidate != null) ...{
                'latitude': candidate['latitude'],
                'longitude': candidate['longitude'],
                'candidate_name': candidate['name'],
                'candidate_address': candidate['address'],
                'source': candidate['source'],
                'source_reference': candidate['source_reference'],
                'confidence': candidate['confidence'],
              },
            },
          )
          as Map,
    );
  }
}
