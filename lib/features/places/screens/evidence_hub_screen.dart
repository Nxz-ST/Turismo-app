import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/widgets/main_navigation_bar.dart';
import '../services/report_place_service.dart';
import '../widgets/evidence_status_badge.dart';
import 'my_contributions_screen.dart';
import 'register_place_screen.dart';

class EvidenceHubScreen extends StatefulWidget {
  const EvidenceHubScreen({super.key});

  @override
  State<EvidenceHubScreen> createState() => _EvidenceHubScreenState();
}

class _EvidenceHubScreenState extends State<EvidenceHubScreen> {
  final _service = ReportPlaceService();
  List<Map<String, dynamic>> _items = const [];
  Map<String, dynamic>? _presence;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _service.obtenerMisAportes(limit: 20),
        PresenceService.instance
            .recent(limit: 1)
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final presence = results[1] as List<Map<String, dynamic>>;
      setState(() {
        _items = results[0] as List<Map<String, dynamic>>;
        _presence = presence.firstOrNull;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyErrorMessage(error);
      });
    }
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
      bottomNavigationBar: const MainNavigationBar(currentIndex: 3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                sliver: SliverToBoxAdapter(child: _header()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(child: _discoveryHero()),
              ),
              if (_presenceRemaining != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(child: _presenceReminder()),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                sliver: SliverToBoxAdapter(child: _impactSection()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(child: _sectionHeader()),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: _message(
                    'No pudimos cargar tus aportes',
                    'Desliza hacia abajo para volver a intentarlo.',
                  ),
                )
              else if (_items.isEmpty)
                SliverToBoxAdapter(
                  child: _message(
                    'Aquí comenzará tu historia',
                    'Tus descubrimientos y fotografías aparecerán en esta sección.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  sliver: SliverList.separated(
                    itemCount: _items.take(4).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _EvidencePreview(item: _items[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Aportar al mapa',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontSize: 29,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      SizedBox(height: 7),
      Text(
        'Ayuda a que más personas descubran el Perú.',
        style: TextStyle(color: AppColors.textLight, fontSize: 14),
      ),
    ],
  );

  Widget _discoveryHero() => Container(
    height: 225,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24073C34),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -34,
          bottom: -38,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .055),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 28,
          top: 26,
          child: Transform.rotate(
            angle: -.08,
            child: Icon(
              Icons.landscape_rounded,
              size: 118,
              color: Colors.white.withValues(alpha: .10),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'FOTOGRAFÍA · UBICACIÓN · VALIDACIÓN',
                  style: TextStyle(
                    color: Color(0xFFAAE6D4),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 270,
                child: Text(
                  'Comparte lo que encontraste',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const SizedBox(
                width: 275,
                child: Text(
                  'No importa si el lugar es nuevo o ya existe: RutaAmiga lo comprobará y guardará tu evidencia correctamente.',
                  style: TextStyle(
                    color: Color(0xFFC6DAD4),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _register,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                label: const Text(
                  'Aportar un lugar',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Duration? get _presenceRemaining {
    final raw = _presence?['recorded_at']?.toString();
    final recordedAt = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (recordedAt == null) return null;
    final remaining = recordedAt
        .add(const Duration(hours: 24))
        .difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Widget _presenceReminder() {
    final remaining = _presenceRemaining!;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Visita activa · ${hours}h ${minutes}min para respaldar un aporte',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _impactSection() {
    final validated = _items
        .where((item) => item['status']?.toString() == 'validated')
        .length;
    final reviewing = _items.where((item) {
      final status = item['status']?.toString();
      return status != 'validated' &&
          status != 'rejected' &&
          status != 'failed';
    }).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tu impacto',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Cada aporte ayuda a construir un mapa más completo.',
          style: TextStyle(color: AppColors.textLight, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _impactMetric('$validated', 'Validados', Icons.verified_outlined),
            const SizedBox(width: 8),
            _impactMetric('$reviewing', 'En revisión', Icons.schedule_rounded),
            const SizedBox(width: 8),
            _impactMetric(
              '${_items.length}',
              'Aportes',
              Icons.landscape_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _impactMetric(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E9E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('Actividad reciente', style: Theme.of(context).textTheme.titleLarge),
      TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyContributionsScreen()),
        ),
        child: const Text('Ver todo'),
      ),
    ],
  );

  Widget _message(String title, String message) => Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.landscape_outlined,
            color: AppColors.primary,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    ),
  );
}

class _EvidencePreview extends StatelessWidget {
  const _EvidencePreview({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final photo = item['photo_url']?.toString();
    final localPhoto = item['photo_local_path']?.toString();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyContributionsScreen()),
      ),
      child: Ink(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5ECE9)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 68,
                height: 68,
                child: localPhoto != null && File(localPhoto).existsSync()
                    ? Image.file(File(localPhoto), fit: BoxFit.cover)
                    : photo == null
                    ? const ColoredBox(
                        color: AppColors.primarySoft,
                        child: Icon(Icons.landscape, color: AppColors.primary),
                      )
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.primarySoft,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Atractivo sin nombre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  EvidenceStatusBadge(status: item['status']?.toString()),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
