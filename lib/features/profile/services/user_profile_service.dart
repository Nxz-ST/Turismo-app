import '../../../core/network/backend_api_client.dart';

/// Perfil de viajero opcional y consentimiento (`/me/profile` en el backend).
class UserProfile {
  const UserProfile({
    this.exists = false,
    this.travelerType,
    this.originRegion,
    this.originCountry,
    this.ageRange,
    this.interests = const [],
    this.hikingExperience,
    this.referralSource,
    this.termsVersion,
    this.termsAcceptedAt,
    this.researchConsent = false,
    this.researchConsentAt,
    this.onboardingCompletedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    exists: json['exists'] == true,
    travelerType: json['traveler_type'] as String?,
    originRegion: json['origin_region'] as String?,
    originCountry: json['origin_country'] as String?,
    ageRange: json['age_range'] as String?,
    interests: (json['interests'] as List? ?? const [])
        .map((item) => item.toString())
        .toList(),
    hikingExperience: json['hiking_experience'] as String?,
    referralSource: json['referral_source'] as String?,
    termsVersion: json['terms_version'] as String?,
    termsAcceptedAt: DateTime.tryParse('${json['terms_accepted_at']}'),
    researchConsent: json['research_consent'] == true,
    researchConsentAt: DateTime.tryParse('${json['research_consent_at']}'),
    onboardingCompletedAt: DateTime.tryParse(
      '${json['onboarding_completed_at']}',
    ),
  );

  final bool exists;
  final String? travelerType;
  final String? originRegion;
  final String? originCountry;
  final String? ageRange;
  final List<String> interests;
  final String? hikingExperience;
  final String? referralSource;
  final String? termsVersion;
  final DateTime? termsAcceptedAt;
  final bool researchConsent;
  final DateTime? researchConsentAt;
  final DateTime? onboardingCompletedAt;

  bool get hasTravelerData =>
      travelerType != null ||
      ageRange != null ||
      interests.isNotEmpty ||
      hikingExperience != null ||
      referralSource != null;
}

class UserProfileService {
  UserProfileService({BackendApiClient? api})
    : _api = api ?? BackendApiClient();

  final BackendApiClient _api;

  Future<UserProfile> fetch() async {
    final response = await _api.get('/me/profile');
    return UserProfile.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Registra la aceptación de Términos y Privacidad. La fecha la pone el
  /// servidor; no modifica los datos del perfil.
  Future<UserProfile> acceptTerms({
    required String version,
    required bool researchConsent,
  }) => _put({
    'accept_terms_version': version,
    'research_consent': researchConsent,
  });

  Future<UserProfile> setResearchConsent(bool value) =>
      _put({'research_consent': value});

  Future<UserProfile> saveTravelerProfile({
    String? travelerType,
    String? originRegion,
    String? originCountry,
    String? ageRange,
    List<String> interests = const [],
    String? hikingExperience,
    String? referralSource,
  }) => _put({
    'traveler_type': travelerType,
    'origin_region': originRegion,
    'origin_country': originCountry,
    'age_range': ageRange,
    'interests': interests,
    'hiking_experience': hikingExperience,
    'referral_source': referralSource,
    'complete_onboarding': true,
  });

  /// "Omitir": no guarda datos, solo marca que ya se ofreció el perfil.
  Future<UserProfile> skipOnboarding() => _put({'complete_onboarding': true});

  Future<UserProfile> _put(Map<String, dynamic> body) async {
    final response = await _api.put('/me/profile', body: body);
    return UserProfile.fromJson(Map<String, dynamic>.from(response as Map));
  }
}
