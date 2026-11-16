class TourismBenefit {
  const TourismBenefit({
    required this.id,
    required this.agencyName,
    required this.agencyInitials,
    required this.title,
    required this.summary,
    required this.benefitLabel,
    required this.originalPrice,
    required this.rutaAmigaPrice,
    required this.duration,
    required this.included,
    required this.conditions,
    required this.rating,
    this.recommended = false,
    this.whatsappPhone,
    this.isDemo = true,
  });

  final String id;
  final String agencyName;
  final String agencyInitials;
  final String title;
  final String summary;
  final String benefitLabel;
  final double originalPrice;
  final double rutaAmigaPrice;
  final String duration;
  final List<String> included;
  final List<String> conditions;
  final double rating;
  final bool recommended;
  final String? whatsappPhone;
  final bool isDemo;

  factory TourismBenefit.fromJson(Map<String, dynamic> json) {
    final agency = Map<String, dynamic>.from(
      json['agency'] as Map? ?? const {},
    );
    return TourismBenefit(
      id: json['id'].toString(),
      agencyName: agency['name']?.toString() ?? 'Agencia asociada',
      agencyInitials: agency['initials']?.toString() ?? 'RA',
      title:
          json['title']?.toString() ??
          json['title_template']?.toString() ??
          'Experiencia RutaAmiga',
      summary:
          json['summary']?.toString() ??
          json['summary_template']?.toString() ??
          '',
      benefitLabel: json['benefit_label']?.toString() ?? 'Beneficio RutaAmiga',
      originalPrice: double.tryParse(json['original_price'].toString()) ?? 0,
      rutaAmigaPrice: double.tryParse(json['rutaamiga_price'].toString()) ?? 0,
      duration: json['duration']?.toString() ?? '',
      included: List<String>.from(
        (json['included'] as List? ?? const []).map(
          (value) => value.toString(),
        ),
      ),
      conditions: List<String>.from(
        (json['conditions'] as List? ?? const []).map(
          (value) => value.toString(),
        ),
      ),
      rating: double.tryParse(json['rating'].toString()) ?? 0,
      recommended: json['recommended'] == true,
      whatsappPhone: agency['whatsapp_phone']?.toString(),
      isDemo: agency['is_demo'] != false || json['is_demo'] != false,
    );
  }

  int get discountPercentage {
    if (originalPrice <= 0 || rutaAmigaPrice >= originalPrice) return 0;
    return (((originalPrice - rutaAmigaPrice) / originalPrice) * 100).round();
  }
}

class BenefitPass {
  const BenefitPass({
    required this.code,
    required this.activatedAt,
    required this.expiresAt,
    this.id,
    this.status = 'requested',
  });

  final String code;
  final DateTime activatedAt;
  final DateTime expiresAt;
  final String? id;
  final String status;

  bool get isActive =>
      expiresAt.isAfter(DateTime.now()) &&
      (status == 'requested' || status == 'confirmed');
}
