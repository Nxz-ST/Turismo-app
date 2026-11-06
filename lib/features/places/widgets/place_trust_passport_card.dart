import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/place_trust_model.dart';
import '../services/place_trust_service.dart';

class PlaceTrustPassportCard extends StatefulWidget {
  const PlaceTrustPassportCard({
    super.key,
    required this.source,
    required this.placeId,
    this.initialTrust,
    this.compact = false,
  });

  final String source;
  final String placeId;
  final PlaceTrustModel? initialTrust;
  final bool compact;

  @override
  State<PlaceTrustPassportCard> createState() => _PlaceTrustPassportCardState();
}

class _PlaceTrustPassportCardState extends State<PlaceTrustPassportCard> {
  late final Future<PlaceTrustModel> _future = widget.initialTrust != null
      ? Future.value(widget.initialTrust)
      : PlaceTrustService().getPassport(
          source: widget.source,
          placeId: widget.placeId,
        );

  @override
  Widget build(BuildContext context) => FutureBuilder<PlaceTrustModel>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _TrustShell(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final trust = snapshot.data;
      if (trust == null) return const SizedBox.shrink();
      return _TrustShell(child: _content(trust));
    },
  );

  Widget _content(PlaceTrustModel trust) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.primary),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Pasaporte de confianza',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
          _LevelBadge(trust: trust),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        trust.source == 'official'
            ? 'Registro oficial complementado con observaciones verificadas de viajeros.'
            : widget.compact
            ? '${trust.independentSupporters} ${trust.independentSupporters == 1 ? 'persona respalda' : 'personas respaldan'} esta ficha mediante aportes independientes.'
            : 'Respaldo comunitario calculado con personas únicas; varios envíos de una persona no inflan el resultado.',
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 12,
          height: 1.4,
        ),
      ),
      if (!widget.compact) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TrustMetric(
                icon: Icons.people_alt_outlined,
                value: '${trust.independentSupporters}',
                label: 'Personas',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TrustMetric(
                icon: Icons.photo_camera_back_outlined,
                value: '${trust.approvedContributors}',
                label: 'Aportantes',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TrustMetric(
                icon: Icons.hiking_outlined,
                value: '${trust.verifiedVisitors}',
                label: 'Visitas GPS',
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 14),
      Row(
        children: [
          const Icon(Icons.update, size: 18, color: AppColors.textLight),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _freshnessLabel(trust),
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      if (trust.placeCondition != null || trust.accessCondition != null) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (trust.placeCondition != null)
              _ConditionChip(
                icon: Icons.landscape_outlined,
                label: _placeCondition(trust.placeCondition!),
              ),
            if (trust.accessCondition != null)
              _ConditionChip(
                icon: Icons.directions_walk_outlined,
                label: _accessCondition(trust.accessCondition!),
              ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      const Text(
        'La corroboración indica coherencia y presencia observada; no reemplaza un registro oficial ni garantiza acceso público.',
        style: TextStyle(color: AppColors.textLight, fontSize: 10, height: 1.4),
      ),
    ],
  );

  String _freshnessLabel(PlaceTrustModel trust) {
    final date = trust.lastVerifiedAt?.toLocal();
    if (date == null) return 'Todavía sin una verificación de campo adicional';
    final days = DateTime.now().difference(date).inDays.clamp(0, 99999);
    if (days == 0) return 'Última verificación: hoy';
    if (days == 1) return 'Última verificación: ayer';
    return 'Última verificación: hace $days días';
  }

  String _placeCondition(String value) => switch (value) {
    'good' => 'Lugar en buen estado',
    'regular' => 'Estado regular',
    'poor' => 'Estado deteriorado',
    _ => 'Estado reportado',
  };

  String _accessCondition(String value) => switch (value) {
    'open' => 'Acceso reportado abierto',
    'difficult' => 'Acceso complicado',
    'blocked' => 'Acceso bloqueado',
    _ => 'Acceso reportado',
  };
}

class _TrustShell extends StatelessWidget {
  const _TrustShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 92),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F8F5),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFD4E7DF)),
    ),
    child: child,
  );
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.trust});

  final PlaceTrustModel trust;

  @override
  Widget build(BuildContext context) {
    final label = switch (trust.trustLevel) {
      'official_registry' => 'Oficial',
      'community_established' => 'Consolidado',
      'community_corroborated' => 'Corroborado',
      _ => 'Inicial',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(color: AppColors.textLight, fontSize: 9),
        ),
      ],
    ),
  );
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}
