import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class EvidenceStatusInfo {
  const EvidenceStatusInfo(this.label, this.color, this.icon, this.description);

  final String label;
  final Color color;
  final IconData icon;
  final String description;

  static EvidenceStatusInfo from(String? status) {
    return switch (status) {
      'offline_pending' => const EvidenceStatusInfo(
        'Pendiente de envío',
        Colors.blueGrey,
        Icons.cloud_upload_outlined,
        'El aporte está guardado en tu dispositivo y se enviará cuando recuperes internet.',
      ),
      'pending' => const EvidenceStatusInfo(
        'Pendiente',
        Colors.blueGrey,
        Icons.schedule,
        'La evidencia está esperando ser procesada.',
      ),
      'processing_ai' => const EvidenceStatusInfo(
        'Analizando',
        Colors.blue,
        Icons.auto_awesome,
        'La inteligencia artificial está revisando la fotografía.',
      ),
      'processing_gis' => const EvidenceStatusInfo(
        'Validando ubicación',
        Colors.indigo,
        Icons.public,
        'Se están contrastando las señales geoespaciales.',
      ),
      'candidate' => const EvidenceStatusInfo(
        'Candidato',
        Colors.orange,
        Icons.stars_outlined,
        'Parece un nuevo atractivo y está listo para revisión.',
      ),
      'needs_review' => const EvidenceStatusInfo(
        'En revisión',
        Colors.amber,
        Icons.rate_review_outlined,
        'Un revisor debe confirmar la decisión final.',
      ),
      'duplicate' => const EvidenceStatusInfo(
        'Posible duplicado',
        Colors.deepOrange,
        Icons.copy_outlined,
        'El lugar parece estar registrado previamente.',
      ),
      'validated' => const EvidenceStatusInfo(
        'Validado',
        AppColors.primary,
        Icons.verified,
        'El lugar fue confirmado como atractivo turístico.',
      ),
      'rejected' => const EvidenceStatusInfo(
        'No aprobado',
        Colors.red,
        Icons.cancel_outlined,
        'La evidencia no cumplió los criterios de validación.',
      ),
      'failed' => const EvidenceStatusInfo(
        'Error',
        Colors.redAccent,
        Icons.error_outline,
        'No se pudo completar el análisis. Inténtalo nuevamente.',
      ),
      _ => const EvidenceStatusInfo(
        'Desconocido',
        Colors.grey,
        Icons.help_outline,
        'No se reconoce el estado actual.',
      ),
    };
  }
}

class EvidenceStatusBadge extends StatelessWidget {
  const EvidenceStatusBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final info = EvidenceStatusInfo.from(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 15, color: info.color),
          const SizedBox(width: 5),
          Text(
            info.label,
            style: TextStyle(
              color: info.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
