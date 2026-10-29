import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../places/widgets/evidence_status_badge.dart';
import '../../places/widgets/evidence_location_card.dart';
import '../../places/widgets/geospatial_signal_card.dart';
import '../../places/widgets/multimodal_score_card.dart';
import '../services/admin_review_service.dart';
import 'coordinate_review_screen.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final AdminReviewService _service = AdminReviewService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.queue();
  }

  Future<void> _reload() async {
    final next = _service.queue();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _review(Map<String, dynamic> item) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReviewSheet(item: item, service: _service),
    );
    if (changed == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de revisión'),
        actions: [
          IconButton(
            tooltip: 'Auditar coordenadas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CoordinateReviewScreen(),
              ),
            ),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 58,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudo abrir el panel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 68, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Todo está revisado',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No hay candidatos pendientes por ahora.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, index) {
                final item = items[index];
                final photo = item['photo_url']?.toString();
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _review(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: photo == null
                              ? ColoredBox(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: const Icon(
                                    Icons.landscape,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Image.network(photo, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name']?.toString() ?? 'Sin nombre',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  EvidenceStatusBadge(
                                    status: item['status']?.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${item['predicted_category'] ?? 'Sin categoría'} · ${_percent(item['confidence'])} confianza',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Spacer(),
                                  Text(
                                    'Revisar evidencia',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: AppColors.primary,
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
              },
            ),
          );
        },
      ),
    );
  }

  String _percent(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    return '${(number * 100).round()}%';
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.item, required this.service});
  final Map<String, dynamic> item;
  final AdminReviewService service;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  static const categories = [
    'bosque',
    'cascada',
    'desierto',
    'lago',
    'montana',
    'nevado',
    'playa',
    'volcan',
  ];
  final reasonController = TextEditingController();
  String? category;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.item['predicted_category']?.toString();
    category = categories.contains(initial) ? initial : null;
    reasonController.text = widget.item['decision_reason']?.toString() ?? '';
  }

  Future<void> _submit(String status) async {
    final reason = reasonController.text.trim();
    if (reason.length < 3 || (status == 'validated' && category == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría y escribe un motivo.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.service.decide(
        evidenceId: widget.item['id'].toString(),
        status: status,
        reason: reason,
        category: category,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.item['photo_url']?.toString();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(photo, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                widget.item['name']?.toString() ?? 'Evidencia',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item['description']?.toString() ?? 'Sin descripción',
                style: const TextStyle(color: AppColors.textLight, height: 1.4),
              ),
              const SizedBox(height: 18),
              MultimodalScoreCard(evidence: widget.item),
              const SizedBox(height: 18),
              EvidenceLocationCard(evidence: widget.item),
              if (widget.item['geospatial_result'] is Map &&
                  (widget.item['geospatial_result'] as Map).isNotEmpty) ...[
                const SizedBox(height: 18),
                GeospatialSignalCard(
                  result: Map<String, dynamic>.from(
                    widget.item['geospatial_result'] as Map,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Categoría final',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_categoryLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) => setState(() => category = value),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                enabled: !saving,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la decisión',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : () => _submit('rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving ? null : () => _submit('validated'),
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified),
                      label: const Text('Validar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String value) => switch (value) {
    'montana' => 'Montaña',
    _ => '${value[0].toUpperCase()}${value.substring(1)}',
  };
}
