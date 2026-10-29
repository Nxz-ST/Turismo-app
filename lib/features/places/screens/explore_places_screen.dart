import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'place_detail_screen.dart';

class ExplorePlacesScreen extends StatelessWidget {
  const ExplorePlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEFE8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.map, size: 120, color: AppColors.primary),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar lugares...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Positioned(bottom: 50, left: 80, child: _buildMapPin()),
                  Positioned(bottom: 90, right: 90, child: _buildMapPin()),
                  Positioned(top: 120, right: 70, child: _buildMapPin()),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Lugares cercanos',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text('Ver todos', style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildPlaceTile(
                    context,
                    'Catarata de Pillones',
                    'Arequipa',
                    '4.8',
                    Icons.landscape,
                  ),
                  const SizedBox(height: 16),
                  _buildPlaceTile(
                    context,
                    'Centro Histórico',
                    'Cusco',
                    '4.7',
                    Icons.account_balance,
                  ),
                  const SizedBox(height: 16),
                  _buildPlaceTile(
                    context,
                    'Bosque de Piedras',
                    'Pasco',
                    '4.6',
                    Icons.terrain,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Icon(Icons.location_on, color: Colors.white),
    );
  }

  Widget _buildPlaceTile(
    BuildContext context,
    String title,
    String location,
    String rating,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaceDetailScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location,
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
