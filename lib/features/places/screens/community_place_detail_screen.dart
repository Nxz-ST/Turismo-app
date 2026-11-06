import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/existing_place_target.dart';
import '../models/place_trust_model.dart';
import '../services/place_trust_service.dart';
import '../widgets/place_trust_passport_card.dart';
import 'register_place_screen.dart';

class CommunityPlaceDetailScreen extends StatefulWidget {
  const CommunityPlaceDetailScreen({super.key, required this.initialPlace});

  final Map<String, dynamic> initialPlace;

  @override
  State<CommunityPlaceDetailScreen> createState() =>
      _CommunityPlaceDetailScreenState();
}

class _CommunityPlaceDetailScreenState
    extends State<CommunityPlaceDetailScreen> {
  late final String _placeId = widget.initialPlace['id'].toString();
  int _heroIndex = 0;
  bool _saved = false;
  late final Future<Map<String, dynamic>> _future = PlaceTrustService()
      .getCommunityPlace(_placeId)
      .catchError((_) => widget.initialPlace);

  static const _savedKey = 'rutaamiga_saved_community_places_v1';

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () => _saved =
          preferences.getStringList(_savedKey)?.contains(_placeId) ?? false,
    );
  }

  Future<void> _toggleSaved() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_savedKey)?.toSet() ?? <String>{};
    if (_saved) {
      saved.remove(_placeId);
    } else {
      saved.add(_placeId);
    }
    await preferences.setStringList(_savedKey, saved.toList());
    if (!mounted) return;
    setState(() => _saved = !_saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _saved
              ? 'Lugar guardado para consultarlo después.'
              : 'Lugar eliminado de guardados.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, snapshot) {
      final place = snapshot.data ?? widget.initialPlace;
      return Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: _bottomActions(place),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              backgroundColor: const Color(0xFF62458C),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leadingWidth: 66,
              leading: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _CommunityHeroAction(
                  tooltip: 'Volver',
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              title: Text(
                place['nombre']?.toString() ?? 'Descubrimiento',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
              actions: [
                _CommunityHeroAction(
                  tooltip: 'Compartir lugar',
                  icon: Icons.ios_share_rounded,
                  onPressed: () => _sharePlace(place),
                ),
                const SizedBox(width: 8),
                _CommunityHeroAction(
                  tooltip: _saved ? 'Quitar de guardados' : 'Guardar lugar',
                  icon: _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  onPressed: _toggleSaved,
                ),
                const SizedBox(width: 14),
              ],
              flexibleSpace: FlexibleSpaceBar(background: _hero(place)),
            ),
            SliverToBoxAdapter(child: _communitySummary(place)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
              sliver: SliverList.list(
                children: [
                  PlaceTrustPassportCard(
                    source: 'community',
                    placeId: _placeId,
                    initialTrust: _trust(place),
                  ),
                  const SizedBox(height: 18),
                  _evolutionCard(place),
                  const SizedBox(height: 28),
                  Text(
                    'Información comunitaria',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  _communityInformation(place),
                  const SizedBox(height: 24),
                  _location(place),
                  const SizedBox(height: 18),
                  const Text(
                    'Este lugar fue documentado por la comunidad. Su corroboración no equivale a un registro oficial ni garantiza que el acceso sea público.',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _hero(Map<String, dynamic> place) {
    final photos = _photos(place);
    if (photos.isEmpty) return _heroFallback();
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (index) => setState(() => _heroIndex = index),
          itemBuilder: (_, index) => Image.network(
            photos[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _heroFallback(),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_heroIndex + 1}/${photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroFallback() => Container(
    color: const Color(0xFFEDE5F4),
    alignment: Alignment.center,
    child: const Icon(
      Icons.landscape_outlined,
      size: 86,
      color: Color(0xFF7655A6),
    ),
  );

  Future<void> _sharePlace(Map<String, dynamic> place) => Share.share(
    'Descubre ${place['nombre'] ?? 'un nuevo lugar'} en RutaAmiga.\n'
    'Un descubrimiento corroborado por la comunidad.',
    subject: place['nombre']?.toString() ?? 'Descubrimiento RutaAmiga',
  );

  Widget _communitySummary(Map<String, dynamic> place) {
    final trust = _trust(place);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2462458C),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _communityBadge(),
          const SizedBox(height: 16),
          Text(
            place['nombre']?.toString() ?? 'Descubrimiento',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              height: 1.08,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.explore_rounded,
                color: Color(0xFF7655A6),
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${_category(place)} · corroborado por viajeros',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _CommunitySummaryFact(
                icon: Icons.photo_library_outlined,
                label: 'Fotos',
                value: '${_photos(place).length}',
              ),
              const SizedBox(width: 10),
              _CommunitySummaryFact(
                icon: Icons.fact_check_outlined,
                label: 'Aportes',
                value: '${_updates(place).length}',
              ),
              const SizedBox(width: 10),
              _CommunitySummaryFact(
                icon: Icons.people_outline_rounded,
                label: 'Respaldo',
                value: '${trust?.independentSupporters ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _communityBadge() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5F4),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF7655A6)),
          SizedBox(width: 6),
          Text(
            'DESCUBRIMIENTO COMUNITARIO',
            style: TextStyle(
              color: Color(0xFF7655A6),
              fontSize: 9,
              letterSpacing: .5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _bottomActions(Map<String, dynamic> place) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x24081712),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Cómo llegar a este lugar',
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _openDirections(place);
                },
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Cómo llegar'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Aportar nueva evidencia para este lugar',
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterPlaceScreen(
                        existingPlace: ExistingPlaceTarget.fromCommunity(place),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Aportar'),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _evolutionCard(Map<String, dynamic> place) {
    final updates = _updates(place);
    final profiles = updates
        .where((update) => update['answers'] is Map)
        .map((update) => Map<String, dynamic>.from(update['answers'] as Map))
        .toList();
    final aggregate = _aggregateProfiles(profiles);
    const fields = <String, String>{
      'access_type': 'acceso',
      'access_difficulty': 'dificultad',
      'cost_type': 'ingreso',
      'place_state': 'estado',
      'activities': 'actividades',
      'services': 'servicios',
      'risks': 'precauciones',
    };
    final pending = fields.entries
        .where((entry) {
          final value = aggregate[entry.key];
          return value == null || (value is List && value.isEmpty);
        })
        .map((entry) => entry.value)
        .toList();
    final confirmed = fields.length - pending.length;
    final trust = _trust(place);
    final supporters = trust?.independentSupporters ?? 0;

    return Semantics(
      label:
          'Evolución de la ficha: ${_photos(place).length} fotos, ${profiles.length} aportes y $supporters personas la respaldan',
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1D6ED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: Color(0xFF7655A6)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cómo está creciendo esta ficha',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _EvolutionMetric(
                  icon: Icons.photo_library_outlined,
                  value: _photos(place).length,
                  label: 'Fotos',
                ),
                _EvolutionMetric(
                  icon: Icons.fact_check_outlined,
                  value: profiles.length,
                  label: 'Aportes',
                ),
                _EvolutionMetric(
                  icon: Icons.people_outline,
                  value: supporters,
                  label: 'Personas',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: confirmed / fields.length,
                      minHeight: 7,
                      backgroundColor: Colors.white,
                      color: const Color(0xFF7655A6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$confirmed/${fields.length}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pending.isEmpty
                  ? 'La información esencial ya fue completada. Nuevos aportes ayudan a mantenerla vigente.'
                  : 'Aún falta confirmar: ${pending.join(', ')}.',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _location(Map<String, dynamic> place) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4EBE8)),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${place['latitud']}, ${place['longitud']}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  PlaceTrustModel? _trust(Map<String, dynamic> place) {
    final raw = place['trust'];
    if (raw is! Map) return null;
    return PlaceTrustModel.fromJson(Map<String, dynamic>.from(raw));
  }

  String _category(Map<String, dynamic> place) =>
      place['categoria_ia']?.toString().trim().isNotEmpty == true
      ? place['categoria_ia'].toString()
      : 'Lugar natural';

  String _description(Map<String, dynamic> place) {
    final value = place['descripcion']?.toString().trim() ?? '';
    return value.isEmpty
        ? 'La ficha todavía necesita información de acceso, actividades y condiciones de visita. Puedes ayudar aportando evidencia desde el lugar.'
        : value;
  }

  Widget _communityInformation(Map<String, dynamic> place) {
    final profiles = _updates(place)
        .where((update) => update['answers'] is Map)
        .map((update) => Map<String, dynamic>.from(update['answers'] as Map))
        .toList();
    if (profiles.isNotEmpty) {
      return _CommunityProfileCard(
        answers: _aggregateProfiles(profiles),
        reportCount: profiles.length,
      );
    }
    return Text(
      _description(place),
      style: const TextStyle(
        color: AppColors.textLight,
        fontSize: 15,
        height: 1.6,
      ),
    );
  }

  Map<String, dynamic> _aggregateProfiles(List<Map<String, dynamic>> profiles) {
    final result = <String, dynamic>{};
    const singleKeys = {
      'access_type',
      'access_difficulty',
      'cost_type',
      'place_state',
    };
    const multipleKeys = {'activities', 'services', 'risks'};

    for (final key in singleKeys) {
      final values = <String>{};
      for (final profile in profiles) {
        final value = profile[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) values.add(value);
      }
      if (values.length > 1) values.remove('unknown');
      if (values.isNotEmpty) result[key] = values.toList();
    }

    for (final key in multipleKeys) {
      final values = <String>{};
      for (final profile in profiles) {
        final raw = profile[key];
        if (raw is List) {
          values.addAll(
            raw
                .map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty),
          );
        }
      }
      if (values.length > 1) values.remove('none_observed');
      if (values.isNotEmpty) result[key] = values.toList();
    }
    return result;
  }

  List<String> _photos(Map<String, dynamic> place) {
    final values = <String>{};
    final primary = place['foto_url']?.toString().trim() ?? '';
    if (primary.isNotEmpty) values.add(primary);
    final raw = place['photos'];
    if (raw is List) {
      values.addAll(
        raw
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty),
      );
    }
    return values.toList();
  }

  List<Map<String, dynamic>> _updates(Map<String, dynamic> place) {
    final raw = place['community_updates'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _openDirections(Map<String, dynamic> place) async {
    final lat = double.tryParse(place['latitud']?.toString() ?? '');
    final lng = double.tryParse(place['longitud']?.toString() ?? '');
    if (lat == null || lng == null) return;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _CommunityProfileCard extends StatelessWidget {
  const _CommunityProfileCard({
    required this.answers,
    required this.reportCount,
  });

  final Map<String, dynamic> answers;
  final int reportCount;

  static const _access = {
    'walking': 'A pie',
    'vehicle': 'En vehículo',
    'public_transport': 'Transporte público',
    'mixed': 'Acceso mixto',
    'unknown': 'Sin confirmar',
  };
  static const _difficulty = {
    'easy': 'Fácil',
    'moderate': 'Moderada',
    'difficult': 'Difícil',
    'unknown': 'Sin confirmar',
  };
  static const _cost = {
    'free': 'Gratuito',
    'paid': 'Pagado',
    'unknown': 'Sin confirmar',
  };
  static const _state = {
    'open': 'Abierto',
    'restricted': 'Restringido',
    'closed': 'Cerrado',
    'unknown': 'Sin confirmar',
  };
  static const _activities = {
    'photography': 'Fotografía',
    'walking': 'Caminata',
    'swimming': 'Baño',
    'nature': 'Naturaleza',
    'culture': 'Cultura',
    'adventure': 'Aventura',
    'relaxation': 'Descanso',
  };
  static const _services = {
    'restrooms': 'Baños',
    'parking': 'Estacionamiento',
    'food': 'Alimentación',
    'guide': 'Guía',
    'signage': 'Señalización',
    'none_observed': 'Ninguno observado',
  };
  static const _risks = {
    'difficult_access': 'Acceso complicado',
    'slippery_surface': 'Piso resbaladizo',
    'strong_current': 'Corriente fuerte',
    'steep_drop': 'Desnivel',
    'low_signal': 'Poca señal',
    'none_observed': 'Ninguna observada',
  };

  @override
  Widget build(BuildContext context) {
    final facts = <({IconData icon, String label, String value})>[
      (
        icon: Icons.directions_walk_rounded,
        label: 'Acceso',
        value: _single('access_type', _access),
      ),
      (
        icon: Icons.terrain_outlined,
        label: 'Dificultad',
        value: _single('access_difficulty', _difficulty),
      ),
      (
        icon: Icons.payments_outlined,
        label: 'Ingreso',
        value: _single('cost_type', _cost),
      ),
      (
        icon: Icons.door_front_door_outlined,
        label: 'Estado',
        value: _single('place_state', _state),
      ),
      if (_multiple('activities', _activities) != null)
        (
          icon: Icons.local_activity_outlined,
          label: 'Actividades',
          value: _multiple('activities', _activities)!,
        ),
      if (_multiple('services', _services) != null)
        (
          icon: Icons.room_service_outlined,
          label: 'Servicios',
          value: _multiple('services', _services)!,
        ),
      if (_multiple('risks', _risks) != null)
        (
          icon: Icons.health_and_safety_outlined,
          label: 'Precauciones',
          value: _multiple('risks', _risks)!,
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reportCount == 1
                      ? 'Datos observados en campo'
                      : 'Resumen de $reportCount aportes de campo',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 9) / 2;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final fact in facts)
                    SizedBox(
                      width: width,
                      child: _ProfileFact(
                        icon: fact.icon,
                        label: fact.label,
                        value: fact.value,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 11),
          Text(
            reportCount == 1
                ? 'Información declarada por un visitante y sujeta a confirmación.'
                : 'Información consolidada de $reportCount aportes. Los valores distintos se muestran juntos y siguen sujetos a confirmación.',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 9,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _single(String key, Map<String, String> labels) {
    final raw = answers[key];
    final values = raw is List ? raw : [raw];
    final resolved = values
        .map((value) => labels[value?.toString()])
        .whereType<String>()
        .toSet()
        .toList();
    return resolved.isEmpty ? 'Sin confirmar' : resolved.join(' / ');
  }

  String? _multiple(String key, Map<String, String> labels) {
    final values = answers[key];
    if (values is! List || values.isEmpty) return null;
    final resolved = values
        .map((value) => labels[value.toString()])
        .whereType<String>()
        .toList();
    return resolved.isEmpty ? null : resolved.join(', ');
  }
}

class _CommunityHeroAction extends StatelessWidget {
  const _CommunityHeroAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: .48),
      foregroundColor: Colors.white,
      minimumSize: const Size(44, 44),
    ),
    icon: Icon(icon, size: 20),
  );
}

class _CommunitySummaryFact extends StatelessWidget {
  const _CommunitySummaryFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DBED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7655A6), size: 20),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 9),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

class _EvolutionMetric extends StatelessWidget {
  const _EvolutionMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF7655A6), size: 20),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 78),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(height: 7),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 8,
            letterSpacing: .5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 11,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
