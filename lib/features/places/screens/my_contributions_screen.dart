import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../../core/widgets/app_network_image.dart';
import '../services/report_place_service.dart';
import '../widgets/evidence_status_badge.dart';
import 'register_place_screen.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  final ReportPlaceService _service = ReportPlaceService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.obtenerMisAportes();
  }

  Future<void> _reload() async {
    final next = _service.obtenerMisAportes();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _register() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPlaceScreen()),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis aportes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Nuevo aporte'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos cargar tus aportes',
              message: friendlyErrorMessage(snapshot.error),
              action: _reload,
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return _MessageState(
              icon: Icons.add_location_alt_outlined,
              title: 'Todavía no tienes aportes',
              message:
                  'Comparte un lugar con una fotografía y RutaAmiga verificará si es nuevo o si ya está registrado.',
              action: _register,
              actionLabel: 'Realizar mi primer aporte',
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, index) => index == 0
                  ? _ContributionsSummary(items: items, onSync: _reload)
                  : _ContributionCard(
                      item: items[index - 1],
                      onChanged: _reload,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ContributionsSummary extends StatelessWidget {
  const _ContributionsSummary({required this.items, required this.onSync});

  final List<Map<String, dynamic>> items;
  final Future<void> Function() onSync;

  int _count(Set<String> statuses) => items
      .where((item) => statuses.contains(item['status']?.toString()))
      .length;

  @override
  Widget build(BuildContext context) {
    final pending = _count({
      'offline_pending',
      'pending',
      'processing_ai',
      'processing_gis',
    });
    final review = _count({'candidate', 'needs_review'});
    final ready = _count({'duplicate', 'validated'});
    final offline = _count({'offline_pending'});
    return Semantics(
      container: true,
      label:
          '$pending aportes procesándose, $review en revisión y $ready incorporados',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de tus aportes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _SummaryMetric(value: pending, label: 'Procesando'),
                _SummaryMetric(value: review, label: 'En revisión'),
                _SummaryMetric(value: ready, label: 'Incorporados'),
              ],
            ),
            if (offline > 0) ...[
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSync,
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(
                    offline == 1
                        ? 'Enviar aporte pendiente'
                        : 'Enviar $offline aportes pendientes',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textLight, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.item, required this.onChanged});

  final Map<String, dynamic> item;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString();
    final info = EvidenceStatusInfo.from(status);
    final photo = item['photo_url']?.toString();
    final localPhoto = item['photo_local_path']?.toString();
    final category = item['predicted_category']?.toString();
    final score = double.tryParse(item['score']?.toString() ?? '');
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        final changed = await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _ContributionDetail(item: item),
        );
        if (changed == true) await onChanged();
      },
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 88,
                height: 88,
                child: localPhoto != null && File(localPhoto).existsSync()
                    ? Image.file(File(localPhoto), fit: BoxFit.cover)
                    : photo == null
                    ? ColoredBox(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.landscape,
                          color: AppColors.primary,
                        ),
                      )
                    : AppNetworkImage(
                        url: photo,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.broken_image_outlined,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Atractivo sin nombre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EvidenceStatusBadge(status: status),
                  if (category != null || score != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (category != null) category,
                        if (score != null) '${(score * 100).round()} puntos',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: info.color),
          ],
        ),
      ),
    );
  }
}

class _ContributionDetail extends StatefulWidget {
  const _ContributionDetail({required this.item});

  final Map<String, dynamic> item;

  @override
  State<_ContributionDetail> createState() => _ContributionDetailState();
}

class _ContributionDetailState extends State<_ContributionDetail> {
  final ReportPlaceService _service = ReportPlaceService();
  bool _working = false;

  Future<void> _retry() async {
    setState(() => _working = true);
    try {
      final count = await _service.retryPending(
        widget.item['client_evidence_id'].toString(),
      );
      if (!mounted) return;
      if (count > 0) {
        Navigator.pop(context, true);
        return;
      }
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El aporte sigue guardado. Lo enviaremos cuando tengas conexión.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar aporte pendiente'),
        content: const Text(
          'Se eliminará la fotografía guardada en este dispositivo. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _working = true);
    await _service.deletePending(widget.item['client_evidence_id'].toString());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final status = item['status']?.toString();
    final isLocal =
        status == 'offline_pending' ||
        (status == 'failed' && item['photo_local_path'] != null);
    final info = EvidenceStatusInfo.from(status);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name']?.toString() ?? 'Aporte',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            EvidenceStatusBadge(status: item['status']?.toString()),
            const SizedBox(height: 16),
            Text(info.description, style: const TextStyle(height: 1.5)),
            if (isLocal) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _working ? null : _retry,
                      icon: _working
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Reintentar'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _UserValidationTimeline(evidence: item),
            if (item['decision_reason'] != null) ...[
              const SizedBox(height: 18),
              const Text(
                'Motivo de la decisión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                friendlyDecisionReason(item['decision_reason']),
                style: const TextStyle(color: AppColors.textLight, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Usamos la fotografía, la presencia del dispositivo y fuentes geográficas. Los detalles técnicos quedan disponibles para los revisores.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
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

class _UserValidationTimeline extends StatelessWidget {
  const _UserValidationTimeline({required this.evidence});

  final Map<String, dynamic> evidence;

  @override
  Widget build(BuildContext context) {
    final status = evidence['status']?.toString() ?? 'pending';
    final offline = status == 'offline_pending';
    final presence = evidence['presence_status']?.toString() ?? 'unavailable';
    final finalReady = [
      'candidate',
      'needs_review',
      'duplicate',
      'validated',
      'rejected',
      'failed',
    ].contains(status);
    final verificationActive = [
      'processing_ai',
      'processing_gis',
    ].contains(status);
    final steps = [
      (
        offline ? 'Guardado en el dispositivo' : 'Foto recibida',
        offline
            ? 'El aporte está protegido y pendiente de conexión.'
            : 'Guardamos tu evidencia de forma segura.',
        true,
        false,
      ),
      (
        'Ubicación comprobada',
        presence == 'confirmed'
            ? 'Tu presencia cerca del lugar fue confirmada.'
            : presence == 'partial'
            ? 'Encontramos una referencia de ubicación parcial.'
            : 'La ubicación se evaluará con las demás señales.',
        !offline && (presence == 'confirmed' || presence == 'partial'),
        false,
      ),
      (
        'Verificando el lugar',
        finalReady
            ? 'Comparamos la imagen y el contexto del lugar.'
            : offline
            ? 'Comenzaremos cuando recuperes internet.'
            : 'Estamos contrastando la evidencia.',
        finalReady,
        verificationActive || status == 'pending' || offline,
      ),
      (
        'Resultado disponible',
        finalReady
            ? EvidenceStatusInfo.from(status).description
            : 'Te avisaremos cuando el resultado esté listo.',
        finalReady,
        false,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso de tu aporte',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 17),
          for (var index = 0; index < steps.length; index++)
            _TimelineStep(
              title: steps[index].$1,
              detail: steps[index].$2,
              completed: steps[index].$3,
              active: steps[index].$4,
              last: index == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.detail,
    required this.completed,
    required this.active,
    required this.last,
  });
  final String title;
  final String detail;
  final bool completed;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? AppColors.success
        : active
        ? AppColors.secondary
        : const Color(0xFFCBD5D1);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed
                        ? Icons.check
                        : active
                        ? Icons.more_horiz
                        : Icons.circle,
                    color: Colors.white,
                    size: completed ? 15 : 12,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: .35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: completed || active
                          ? AppColors.textDark
                          : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    this.actionLabel = 'Reintentar',
  });
  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() action;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.primary),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: action, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
