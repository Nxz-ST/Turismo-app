import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MultimodalScoreCard extends StatelessWidget {
  const MultimodalScoreCard({super.key, required this.evidence});

  final Map<String, dynamic> evidence;

  @override
  Widget build(BuildContext context) {
    final details = Map<String, dynamic>.from(
      evidence['validation_details'] as Map? ?? const {},
    );
    final components = Map<String, dynamic>.from(
      details['component_scores'] as Map? ?? const {},
    );
    final score = _ratio(evidence['score'] ?? details['score']);
    final coverage = _ratio(
      evidence['evidence_coverage'] ?? details['coverage'],
    );
    if (score == null && coverage == null && components.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Score multimodal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metric('Plausibilidad', score, AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metric('Cobertura', coverage, const Color(0xFF0F9D76)),
              ),
            ],
          ),
          if (components.isNotEmpty) ...[
            const SizedBox(height: 16),
            _component('Modelo visual', components['visual']),
            _component('Captura y GPS', components['capture']),
            _component('Ambiente y relieve', components['geospatial']),
          ],
          const SizedBox(height: 8),
          Text(
            'Resultado preliminar; la validación definitiva corresponde a un revisor.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textLight,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, double? value, Color color) {
    final safeValue = value ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value == null ? '—' : '${(safeValue * 100).round()}%',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: safeValue.clamp(0, 1),
          color: color,
          backgroundColor: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
      ],
    );
  }

  Widget _component(String label, dynamic raw) {
    final data = Map<String, dynamic>.from(raw as Map? ?? const {});
    if (data.isEmpty) return const SizedBox.shrink();
    final value = _ratio(data['score']);
    final weight = _ratio(data['weight']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            '${value == null ? '—' : '${(value * 100).round()}%'} · peso ${(weight ?? 0) * 100}%',
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  double? _ratio(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '');
    if (number == null) return null;
    return number.clamp(0, 1).toDouble();
  }
}
