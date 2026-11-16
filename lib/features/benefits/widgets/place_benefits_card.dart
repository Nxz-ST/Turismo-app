import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/tourism_benefits_screen.dart';

class PlaceBenefitsCard extends StatelessWidget {
  const PlaceBenefitsCard({
    super.key,
    required this.placeKey,
    required this.placeName,
    required this.category,
    required this.locationLabel,
  });

  final String placeKey;
  final String placeName;
  final String category;
  final String locationLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ver beneficios para visitar $placeName',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TourismBenefitsScreen(
              placeKey: placeKey,
              placeName: placeName,
              category: category,
              locationLabel: locationLabel,
            ),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F6955), Color(0xFF15463D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2615463D),
                blurRadius: 20,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8C9),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.redeem_rounded,
                  color: Color(0xFFB66708),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'BENEFICIOS RUTAAMIGA',
                          style: TextStyle(
                            color: Color(0xFFBDE8D9),
                            fontSize: 9,
                            letterSpacing: .7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Ahorra en tu próxima visita',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Compara 3 experiencias de operadores aliados.',
                      style: TextStyle(
                        color: Color(0xFFD7EAE4),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
