import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              color: AppColors.primary.withValues(alpha: 0.15),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.landscape,
                      size: 120,
                      color: AppColors.primary,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: AppColors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.textDark,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: AppColors.white,
                      child: Icon(
                        Icons.favorite_border,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catarata de Pillones',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Arequipa, Perú',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 6),
                          Text(
                            '4.8',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '(328 reseñas)',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: const [
                          _InfoBox(
                            icon: Icons.access_time,
                            title: 'Horario',
                            value: '8:00 - 18:00',
                          ),
                          SizedBox(width: 12),
                          _InfoBox(
                            icon: Icons.route,
                            title: 'Distancia',
                            value: '1.2 km',
                          ),
                          SizedBox(width: 12),
                          _InfoBox(
                            icon: Icons.accessible,
                            title: 'Acceso',
                            value: 'Sí',
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Hermosa catarata rodeada de naturaleza, ideal para relajarse, tomar fotografías y disfrutar de una experiencia turística cercana.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textLight,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.navigation),
                          label: const Text(
                            '¡Vamos! Dame la ruta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
