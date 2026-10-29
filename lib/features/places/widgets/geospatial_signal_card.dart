import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class GeospatialSignalCard extends StatelessWidget {
  const GeospatialSignalCard({super.key, required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    if (result.isEmpty) return const SizedBox.shrink();
    final sentinel = Map<String, dynamic>.from(
      result['sentinel'] as Map? ?? const {},
    );
    final terrain = Map<String, dynamic>.from(
      result['terrain'] as Map? ?? const {},
    );
    final coherence = Map<String, dynamic>.from(
      result['coherence'] as Map? ?? const {},
    );
    final indices = Map<String, dynamic>.from(
      sentinel['indices'] as Map? ?? const {},
    );
    final satelliteAvailable = sentinel['status'] == 'available';
    final terrainAvailable = terrain['status'] == 'available';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9EAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.satellite_alt_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Respaldo geoespacial',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _signal(
            Icons.cloud_outlined,
            'Sentinel-2',
            satelliteAvailable
                ? '${_date(sentinel['acquired_at'])} · ${_number(sentinel['cloud_cover_percent'])}% nubes · ${_number(sentinel['resolution_m'])} m'
                : sentinel['reason']?.toString() ?? 'Sin escena disponible',
          ),
          if (indices.isNotEmpty) ...[
            const SizedBox(height: 10),
            _signal(
              Icons.analytics_outlined,
              'Índices',
              [
                'NDVI ${_decimal(indices['ndvi'])}',
                'NDWI ${_decimal(indices['ndwi'])}',
                'NDSI ${_decimal(indices['ndsi'])}',
                'BSI ${_decimal(indices['bsi'])}',
              ].join(' · '),
            ),
          ],
          const SizedBox(height: 10),
          _signal(
            Icons.terrain_outlined,
            'Elevación',
            terrainAvailable
                ? '${_number(terrain['elevation_m'])} m · relieve ${_number(terrain['local_relief_m'])} m · pendiente ${_number(terrain['estimated_slope_percent'])}%'
                : terrain['reason']?.toString() ?? 'Sin datos de elevación',
          ),
          if (coherence.isNotEmpty) ...[
            const SizedBox(height: 10),
            _signal(
              coherence['state'] == 'contradicts'
                  ? Icons.warning_amber_rounded
                  : Icons.fact_check_outlined,
              'Coherencia',
              coherence['explanation']?.toString() ?? 'No concluyente',
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Estas señales apoyan la revisión, pero no confirman por sí solas que un lugar sea turístico.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signal(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.textDark, fontSize: 13),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _number(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '');
    if (number == null) return '—';
    return number == number.roundToDouble()
        ? number.round().toString()
        : number.toStringAsFixed(1);
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Fecha desconocida';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _decimal(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '');
    return number?.toStringAsFixed(2) ?? '—';
  }
}
