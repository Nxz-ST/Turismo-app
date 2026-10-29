import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../places/models/tourist_place_model.dart';
import '../../places/screens/map_screen.dart';

class TourismPlanDetailScreen extends StatelessWidget {
  final String title;
  final List<TouristPlaceModel> places;
  final String duration;
  final double distance;

  const TourismPlanDetailScreen({
    super.key,
    required this.title,
    required this.places,
    required this.duration,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new),
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Text(
                    'Plan turístico',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Recorrido sugerido según los atractivos turísticos cercanos a tu ubicación actual.',
                style: const TextStyle(
                  color: AppColors.textLight,
                  height: 1.5,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  _summaryCard(
                    Icons.near_me,
                    'Distancia',
                    '${distance.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: 14),
                  _summaryCard(Icons.access_time, 'Duración', duration),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Paradas del recorrido',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              ...places.asMap().entries.map(
                (entry) => _stopCard(index: entry.key + 1, place: entry.value),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(routePlaces: places),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text(
                    'Ver recorrido en mapa',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stopCard({required int index, required TouristPlaceModel place}) {
    final description = place.descripcion.isNotEmpty
        ? place.descripcion
        : 'No hay descripción disponible.';

    final activities = place.actividades.isNotEmpty
        ? place.actividades
        : 'Actividades no disponibles.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${place.distrito}, ${place.provincia}',
                  style: const TextStyle(color: AppColors.textLight),
                ),

                const SizedBox(height: 12),

                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Actividades: $activities',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
