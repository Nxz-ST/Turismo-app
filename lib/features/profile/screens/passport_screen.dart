import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../routes/services/route_visit_service.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  final _service = RouteVisitService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.passport();
  }

  Future<void> _refresh() async {
    final next = _service.passport();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pasaporte RutaAmiga')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final visits = snapshot.data ?? const [];
        if (visits.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(30),
              children: const [
                SizedBox(height: 130),
                Icon(
                  Icons.auto_stories_outlined,
                  size: 72,
                  color: AppColors.primary,
                ),
                SizedBox(height: 18),
                Text(
                  'Tu pasaporte está listo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Inicia una ruta y registra tu llegada para guardar aquí cada lugar visitado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight, height: 1.4),
                ),
              ],
            ),
          );
        }
        final verified = visits
            .where((visit) => visit['visit_verified'] == true)
            .length;
        final verifiedVisits = visits
            .where((visit) => visit['visit_verified'] == true)
            .toList();
        final routes = verifiedVisits
            .map((visit) => visit['route_id']?.toString() ?? '')
            .where((route) => route.isNotEmpty)
            .toSet()
            .length;
        final regionNames =
            verifiedVisits
                .map(
                  (visit) =>
                      _department(visit['place_region']?.toString() ?? ''),
                )
                .where((region) => region.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, Color(0xFF14786E)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Tu historia viajando por el Perú',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _stat('$verified', 'Visitas'),
                        _stat('$routes', 'Rutas'),
                        _stat('${regionNames.length}', 'Regiones'),
                      ],
                    ),
                  ],
                ),
              ),
              if (regionNames.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Regiones exploradas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final region in regionNames)
                      Chip(
                        avatar: const Icon(Icons.place_outlined, size: 16),
                        label: Text(region),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              const Text(
                'Sellos de viaje',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final visit in visits) _visitCard(visit),
            ],
          ),
        );
      },
    ),
  );

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _visitCard(Map<String, dynamic> visit) {
    final verified = visit['visit_verified'] == true;
    final pending = visit['sync_status'] == 'pending';
    final rating = (visit['rating'] as num?)?.toInt() ?? 0;
    final date = DateTime.tryParse(
      visit['captured_at']?.toString() ?? '',
    )?.toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E9E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(width: 84, height: 94, child: _photo(visit)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        visit['place_name']?.toString() ?? 'Lugar visitado',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Icon(
                      verified
                          ? Icons.verified_rounded
                          : Icons.schedule_rounded,
                      color: verified ? AppColors.success : Colors.orange,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  visit['place_region']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${'★' * rating}${'☆' * (5 - rating)}',
                  style: const TextStyle(
                    color: Color(0xFFF2A93B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pending
                      ? 'Pendiente de sincronización'
                      : verified
                      ? 'Visita verificada por GPS'
                      : 'Visita guardada sin verificación',
                  style: TextStyle(
                    color: verified ? AppColors.success : Colors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo(Map<String, dynamic> visit) {
    final url = visit['photo_url']?.toString();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoFallback(),
      );
    }
    final localPath = visit['photo_local_path']?.toString();
    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }
    return _photoFallback();
  }

  Widget _photoFallback() => const ColoredBox(
    color: AppColors.primarySoft,
    child: Icon(Icons.landscape_rounded, color: AppColors.primary),
  );

  static String _department(String value) {
    if (value.trim().isEmpty) return '';
    return value.split(',').last.trim();
  }
}
