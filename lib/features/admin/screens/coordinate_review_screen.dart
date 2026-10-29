import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/admin_review_service.dart';

class CoordinateReviewScreen extends StatefulWidget {
  const CoordinateReviewScreen({super.key});

  @override
  State<CoordinateReviewScreen> createState() => _CoordinateReviewScreenState();
}

class _CoordinateReviewScreenState extends State<CoordinateReviewScreen> {
  final _service = AdminReviewService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.coordinateQueue();
  }

  Future<void> _reload() async {
    final next = _service.coordinateQueue();
    setState(() => _future = next);
    await next;
  }

  Future<void> _open(Map<String, dynamic> review) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CoordinateReviewSheet(review: review, service: _service),
    );
    if (changed == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría de coordenadas'),
        actions: [
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
            return _CoordinateError(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final reviews = snapshot.data ?? const [];
          if (reviews.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.where_to_vote_outlined,
                      size: 66,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay puntos pendientes',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Las correcciones aplicadas conservan su historial en la base de datos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final review = reviews[index];
                final place = Map<String, dynamic>.from(
                  review['place'] as Map? ?? const {},
                );
                return Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _open(review),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1DC),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.location_searching,
                              color: Color(0xFFC67A09),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place['nombre']?.toString() ??
                                      'Lugar ${review['place_id']}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _area(place),
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _Tag(
                                      label: review['status'] == 'candidate'
                                          ? 'Candidato guardado'
                                          : 'Coordenada repetida',
                                      color: review['status'] == 'candidate'
                                          ? AppColors.primary
                                          : const Color(0xFFC67A09),
                                    ),
                                    _Tag(
                                      label:
                                          '${_decimal(review['original_latitude'])}, ${_decimal(review['original_longitude'])}',
                                      color: AppColors.textLight,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
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

  static String _area(Map<String, dynamic> place) {
    final values =
        [place['distrito'], place['provincia'], place['departamento']]
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty);
    return values.isEmpty
        ? 'Ubicación administrativa no disponible'
        : values.join(' · ');
  }

  static String _decimal(dynamic value) =>
      (double.tryParse(value?.toString() ?? '') ?? 0).toStringAsFixed(5);
}

class _CoordinateReviewSheet extends StatefulWidget {
  const _CoordinateReviewSheet({required this.review, required this.service});

  final Map<String, dynamic> review;
  final AdminReviewService service;

  @override
  State<_CoordinateReviewSheet> createState() => _CoordinateReviewSheetState();
}

class _CoordinateReviewSheetState extends State<_CoordinateReviewSheet> {
  final _noteController = TextEditingController();
  List<Map<String, dynamic>>? _suggestions;
  int? _selected;
  bool _loading = false;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _selected = null;
    });
    try {
      final result = await widget.service.coordinateSuggestions(
        widget.review['id'].toString(),
      );
      if (!mounted) return;
      setState(() {
        _suggestions = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(error.toString());
    }
  }

  Future<void> _submit(String action) async {
    final note = _noteController.text.trim();
    final requiresCandidate = action != 'reject';
    if (note.length < 3 || (requiresCandidate && _selected == null)) {
      _message(
        requiresCandidate
            ? 'Selecciona un candidato y explica por qué corresponde al lugar.'
            : 'Escribe el motivo para cerrar este caso.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.decideCoordinate(
        reviewId: widget.review['id'].toString(),
        action: action,
        note: note,
        candidate: requiresCandidate ? _suggestions![_selected!] : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message(error.toString());
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final place = Map<String, dynamic>.from(
      widget.review['place'] as Map? ?? const {},
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          0,
          22,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place['nombre']?.toString() ?? 'Revisar ubicación',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _CoordinateReviewScreenState._area(place),
                style: const TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFC67A09)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Una sugerencia es solo un candidato. Comprueba el nombre, el distrito y si representa el atractivo o su acceso.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _loading || _saving ? null : _search,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.travel_explore),
                  label: const Text('Buscar candidatos geográficos'),
                ),
              ),
              if (_suggestions != null) ...[
                const SizedBox(height: 14),
                if (_suggestions!.isEmpty)
                  const Text(
                    'No se encontraron coincidencias. Mantén el punto como referencial.',
                    style: TextStyle(color: AppColors.textLight),
                  )
                else
                  ...List.generate(_suggestions!.length, (index) {
                    final item = _suggestions![index];
                    final distance =
                        (double.tryParse(
                              item['distance_from_reported_m']?.toString() ??
                                  '',
                            ) ??
                            0) /
                        1000;
                    final confidence =
                        (double.tryParse(
                          item['confidence']?.toString() ?? '',
                        ) ??
                        0);
                    return RadioListTile<int>(
                      value: index,
                      groupValue: _selected,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _selected = value),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item['name']?.toString() ?? 'Candidato',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item['address'] ?? 'Sin dirección'}\n${distance.toStringAsFixed(1)} km desde el punto reportado · prioridad ${(confidence * 100).round()}%',
                      ),
                    );
                  }),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Motivo y fuente comprobada',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _submit('reject'),
                      child: const Text('Mantener referencial'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _submit('approve_coordinate'),
                      child: const Text('Corregir lugar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : () => _submit('approve_access'),
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('Usar únicamente como punto de acceso'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CoordinateError extends StatelessWidget {
  const _CoordinateError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 58),
            const SizedBox(height: 14),
            const Text(
              'No se pudo cargar la auditoría',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
