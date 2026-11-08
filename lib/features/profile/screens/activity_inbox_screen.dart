import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../places/screens/my_contributions_screen.dart';
import '../../places/services/report_place_service.dart';

class ActivityInboxScreen extends StatefulWidget {
  const ActivityInboxScreen({super.key});

  @override
  State<ActivityInboxScreen> createState() => _ActivityInboxScreenState();
}

class _ActivityInboxScreenState extends State<ActivityInboxScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String get _seenKey =>
      'rutaamiga_activity_seen_v1_${Supabase.instance.client.auth.currentUser?.id ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _future = ReportPlaceService().obtenerMisAportes(limit: 60);
  }

  Future<void> _reload() async {
    final next = ReportPlaceService().obtenerMisAportes(limit: 60);
    setState(() => _future = next);
    await next;
  }

  Future<void> _markSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _seenKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novedades de tu actividad')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _InboxState(
            icon: Icons.cloud_off_outlined,
            title: 'No pudimos actualizar tu actividad',
            message: friendlyErrorMessage(snapshot.error),
            onRetry: _reload,
          );
        }
        final items = snapshot.data ?? const [];
        WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());
        if (items.isEmpty) {
          return const _InboxState(
            icon: Icons.notifications_none_rounded,
            title: 'Todavía no hay novedades',
            message: 'Cuando envíes un aporte, su avance aparecerá aquí.',
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _ActivityCard(item: items[index]),
          ),
        );
      },
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'pending';
    final presentation = _presentation(status);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyContributionsScreen()),
      ),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E9E6)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: presentation.$3,
              foregroundColor: presentation.$2,
              child: Icon(presentation.$1),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Tu aporte',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    presentation.$4,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _date(item['updated_at'] ?? item['created_at']),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  static (IconData, Color, Color, String) _presentation(
    String status,
  ) => switch (status) {
    'validated' => (
      Icons.verified_rounded,
      AppColors.success,
      AppColors.primarySoft,
      'Lugar validado. Completa su información si todavía está pendiente.',
    ),
    'duplicate' => (
      Icons.hub_outlined,
      const Color(0xFF7655A6),
      const Color(0xFFF0E8F8),
      'Tu evidencia fue incorporada a una ficha que ya existía.',
    ),
    'rejected' => (
      Icons.info_outline_rounded,
      AppColors.danger,
      const Color(0xFFFFECEE),
      'El aporte no fue aprobado. Revisa el motivo y las recomendaciones.',
    ),
    'candidate' || 'needs_review' => (
      Icons.rate_review_outlined,
      AppColors.warning,
      const Color(0xFFFFF4DD),
      'El análisis terminó y el caso está esperando revisión humana.',
    ),
    'failed' => (
      Icons.sync_problem_rounded,
      AppColors.danger,
      const Color(0xFFFFECEE),
      'No pudimos terminar el proceso. Puedes reintentarlo desde Mis aportes.',
    ),
    'offline_pending' => (
      Icons.cloud_upload_outlined,
      AppColors.warning,
      const Color(0xFFFFF4DD),
      'El aporte está guardado y se enviará cuando tengas conexión.',
    ),
    _ => (
      Icons.auto_awesome_rounded,
      AppColors.primary,
      AppColors.primarySoft,
      'RutaAmiga está contrastando la fotografía y la ubicación.',
    ),
  };

  static String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Actualización reciente';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InboxState extends StatelessWidget {
  const _InboxState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 17),
            FilledButton(
              onPressed: () => onRetry!(),
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    ),
  );
}
