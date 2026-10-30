import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../services/active_route_service.dart';

class ActiveRouteCard extends StatefulWidget {
  const ActiveRouteCard({
    super.key,
    required this.route,
    required this.onContinue,
    this.compact = false,
  });

  final Map<String, dynamic> route;
  final VoidCallback onContinue;
  final bool compact;

  @override
  State<ActiveRouteCard> createState() => _ActiveRouteCardState();
}

class _ActiveRouteCardState extends State<ActiveRouteCard> {
  int _completed = 0;

  List<Map<String, dynamic>> get _stops =>
      (widget.route['stops'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final value =
        preferences.getInt(ActiveRouteService.progressKey(widget.route)) ?? 0;
    if (mounted) setState(() => _completed = value.clamp(0, _stops.length));
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;
    if (stops.isEmpty) return const SizedBox.shrink();
    final completed = _completed >= stops.length;
    final next = stops[_completed.clamp(0, stops.length - 1)];
    final progress = stops.isEmpty ? 0.0 : _completed / stops.length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onContinue,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.fromLTRB(
            widget.compact ? 16 : 20,
            widget.compact ? 13 : 16,
            widget.compact ? 13 : 20,
            widget.compact ? 13 : 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A073C34),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: widget.compact ? 40 : 54,
                    height: widget.compact ? 40 : 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: widget.compact ? 21 : 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECORRIDO ACTIVO',
                          style: TextStyle(
                            color: Color(0xFF9DE5D1),
                            fontSize: widget.compact ? 9 : 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .9,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          completed
                              ? 'Recorrido listo para finalizar'
                              : 'En camino a ${next['name'] ?? 'la siguiente parada'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.compact ? 15 : 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          completed
                              ? '${widget.route['title'] ?? 'Tu ruta'} · ${stops.length} de ${stops.length}'
                              : '${widget.route['title'] ?? 'Tu ruta'} · ${_completed + 1} de ${stops.length}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFC7DAD5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: widget.compact ? 4 : 7,
                  value: progress,
                  color: const Color(0xFF67D5B5),
                  backgroundColor: Colors.white24,
                ),
              ),
              if (!widget.compact) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle_outline_rounded
                          : Icons.flag_outlined,
                      color: const Color(0xFF9DE5D1),
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '$_completed de ${stops.length} paradas visitadas',
                        style: const TextStyle(
                          color: Color(0xFFC7DAD5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continuar',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primaryDark,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
