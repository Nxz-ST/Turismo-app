class PlaceTrustModel {
  const PlaceTrustModel({
    required this.placeId,
    required this.source,
    required this.trustLevel,
    required this.verifiedVisitors,
    required this.approvedContributors,
    required this.independentSupporters,
    required this.freshness,
    this.lastVerifiedAt,
    this.placeCondition,
    this.accessCondition,
  });

  final String placeId;
  final String source;
  final String trustLevel;
  final int verifiedVisitors;
  final int approvedContributors;
  final int independentSupporters;
  final String freshness;
  final DateTime? lastVerifiedAt;
  final String? placeCondition;
  final String? accessCondition;

  factory PlaceTrustModel.fromJson(Map<String, dynamic> json) =>
      PlaceTrustModel(
        placeId: json['place_id']?.toString() ?? '',
        source: json['source']?.toString() ?? 'community',
        trustLevel: json['trust_level']?.toString() ?? 'community_initial',
        verifiedVisitors:
            int.tryParse(json['verified_visitors']?.toString() ?? '') ?? 0,
        approvedContributors:
            int.tryParse(json['approved_contributors']?.toString() ?? '') ?? 0,
        independentSupporters:
            int.tryParse(json['independent_supporters']?.toString() ?? '') ?? 0,
        freshness: json['freshness']?.toString() ?? 'unverified',
        lastVerifiedAt: DateTime.tryParse(
          json['last_verified_at']?.toString() ?? '',
        ),
        placeCondition: json['place_condition']?.toString(),
        accessCondition: json['access_condition']?.toString(),
      );
}
