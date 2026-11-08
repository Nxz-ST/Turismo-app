import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/utils/display_text.dart';
import '../models/existing_place_target.dart';
import '../models/tourist_place_model.dart';
import '../models/place_trust_model.dart';
import '../services/place_trust_service.dart';
import '../widgets/place_trust_passport_card.dart';
import '../widgets/place_issue_report_button.dart';
import 'register_place_screen.dart';
import '../../profile/screens/my_trip_screen.dart';
import '../../profile/services/travel_library_service.dart';

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
  bool _inTrip = false;
  late final Future<Map<String, dynamic>> _future = PlaceTrustService()
      .getCommunityPlace(_placeId)
      .catchError((_) => widget.initialPlace);

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _loadTripState();
  }

  Future<void> _loadTripState() async {
    final inTrip = await TravelLibraryService.instance.isInTrip(
      TouristPlaceModel.fromCommunity(widget.initialPlace),
    );
    if (mounted) setState(() => _inTrip = inTrip);
  }

  Future<void> _loadSavedState() async {
    final saved = await TravelLibraryService.instance.isFavorite(
      TouristPlaceModel.fromCommunity(widget.initialPlace),
    );
    if (!mounted) return;
    setState(() => _saved = saved);
  }

  Future<void> _toggleSaved(Map<String, dynamic> source) async {
    final added = await TravelLibraryService.instance.toggleFavorite(
      TouristPlaceModel.fromCommunity(source),
    );
    if (!mounted) return;
    setState(() => _saved = added);
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
                _displayName(place),
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
                  onPressed: () => _toggleSaved(place),
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
                  _communityStory(place),
                  const SizedBox(height: 26),
                  Text(
                    'Lo esencial para tu visita',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Información práctica observada directamente por viajeros.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  _communityInformation(place),
                  if (_updates(place).isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _communityTimeline(place),
                  ],
                  const SizedBox(height: 22),
                  _sourceClarityCard(place),
                  const SizedBox(height: 26),
                  _contributionPrompt(place),
                  const SizedBox(height: 8),
                  PlaceIssueReportButton(
                    source: 'community',
                    placeId: _placeId,
                    placeName: _displayName(place),
                  ),
                  const SizedBox(height: 20),
                  PlaceTrustPassportCard(
                    source: 'community',
                    placeId: _placeId,
                    initialTrust: _trust(place),
                    compact: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ubicación',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
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
          itemBuilder: (_, index) =>
              AppNetworkImage(url: photos[index], fit: BoxFit.cover),
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
    'Descubre ${_displayName(place)} en RutaAmiga.\n'
    'Un descubrimiento corroborado por la comunidad.',
    subject: _displayName(place),
  );

  Widget _communitySummary(Map<String, dynamic> place) {
    final trust = _trust(place);
    final supporters = trust?.independentSupporters ?? 0;
    final photos = _photos(place).length;
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
            _displayName(place),
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDF8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: Color(0xFF7655A6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$supporters ${supporters == 1 ? 'viajero respalda' : 'viajeros respaldan'} este lugar · $photos ${photos == 1 ? 'foto' : 'fotos'}',
                    style: const TextStyle(
                      color: Color(0xFF62458C),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _freshnessShort(trust),
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _tripAction(place),
        ],
      ),
    );
  }

  Widget _tripAction(Map<String, dynamic> place) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      button: true,
      label: _inTrip
          ? 'Abrir este lugar en Mi viaje'
          : 'Planificar una visita a este lugar',
      child: Material(
        color: _inTrip ? const Color(0xFFE7F2ED) : const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: _inTrip
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTripScreen()),
                )
              : () => _addToTrip(place),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _inTrip
                      ? Icons.check_circle_outline_rounded
                      : Icons.event_available_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Text(
                  _inTrip ? 'En Mi viaje' : 'Planificar visita',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (_inTrip) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

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
                  _openContribution(place);
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

  void _openContribution(Map<String, dynamic> place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPlaceScreen(
          existingPlace: ExistingPlaceTarget.fromCommunity(place),
        ),
      ),
    );
  }

  Future<void> _addToTrip(Map<String, dynamic> place) async {
    HapticFeedback.selectionClick();
    final added = await TravelLibraryService.instance.addToTrip(
      TouristPlaceModel.fromCommunity(place),
    );
    if (!mounted) return;
    setState(() => _inTrip = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Lugar añadido a Mi viaje.'
              : 'Este lugar ya estaba en Mi viaje.',
        ),
      ),
    );
  }

  String _freshnessShort(PlaceTrustModel? trust) {
    final date = trust?.lastVerifiedAt?.toLocal();
    if (date == null) return 'Por actualizar';
    final days = DateTime.now().difference(date).inDays.clamp(0, 99999);
    if (days == 0) return 'Actualizado hoy';
    if (days == 1) return 'Actualizado ayer';
    return 'Hace $days días';
  }

  List<Map<String, dynamic>> _profiles(Map<String, dynamic> place) =>
      _updates(place)
          .where((update) => update['answers'] is Map)
          .map((update) => Map<String, dynamic>.from(update['answers'] as Map))
          .toList();

  Widget _communityStory(Map<String, dynamic> place) {
    final aggregate = _aggregateProfiles(_profiles(place));
    final narrative = _communityNarrative(place, aggregate);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF183F36), Color(0xFF27594E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24183F36),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFC9F2E3)),
              SizedBox(width: 8),
              Text(
                'Conoce este lugar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            narrative,
            style: const TextStyle(
              color: Color(0xFFEAF6F1),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _storyHighlights(aggregate),
          ),
        ],
      ),
    );
  }

  String _communityNarrative(
    Map<String, dynamic> place,
    Map<String, dynamic> aggregate,
  ) {
    final activities = _labelsFor(aggregate['activities'], const {
      'photography': 'fotografía',
      'walking': 'caminatas',
      'swimming': 'baño',
      'nature': 'naturaleza',
      'culture': 'cultura',
      'adventure': 'aventura',
      'relaxation': 'descanso',
    });
    final difficulty = _firstLabel(aggregate['access_difficulty'], const {
      'easy': 'fácil',
      'moderate': 'moderada',
      'difficult': 'exigente',
    });
    final activityText = activities.isEmpty
        ? 'conocer un paisaje documentado por la comunidad'
        : activities.take(3).join(', ');
    final difficultyText = difficulty == null
        ? 'La dificultad del acceso aún necesita confirmación.'
        : 'Los viajeros reportan una dificultad $difficulty.';
    return '${_displayName(place)} es un lugar de tipo ${_category(place).toLowerCase()}, recomendado para $activityText. $difficultyText Revisa las condiciones antes de salir, porque la información puede cambiar.';
  }

  List<Widget> _storyHighlights(Map<String, dynamic> aggregate) {
    final highlights = <({IconData icon, String label})>[];
    final cost = _firstLabel(aggregate['cost_type'], const {
      'free': 'Ingreso gratuito',
      'paid': 'Ingreso pagado',
    });
    final state = _firstLabel(aggregate['place_state'], const {
      'open': 'Acceso abierto',
      'restricted': 'Acceso restringido',
      'closed': 'Reportado cerrado',
    });
    final access = _firstLabel(aggregate['access_type'], const {
      'walking': 'Acceso a pie',
      'vehicle': 'Acceso vehicular',
      'public_transport': 'Transporte público',
      'mixed': 'Acceso mixto',
    });
    if (cost != null) {
      highlights.add((icon: Icons.payments_outlined, label: cost));
    }
    if (state != null) {
      highlights.add((icon: Icons.door_front_door_outlined, label: state));
    }
    if (access != null) {
      highlights.add((icon: Icons.directions_walk_rounded, label: access));
    }
    if (highlights.isEmpty) {
      highlights.add((
        icon: Icons.help_outline_rounded,
        label: 'Información en construcción',
      ));
    }
    return [
      for (final item in highlights)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: const Color(0xFFC9F2E3)),
              const SizedBox(width: 5),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  String? _firstLabel(dynamic raw, Map<String, String> labels) {
    final values = raw is List ? raw : [raw];
    for (final value in values) {
      final label = labels[value?.toString()];
      if (label != null) return label;
    }
    return null;
  }

  List<String> _labelsFor(dynamic raw, Map<String, String> labels) {
    if (raw is! List) return const [];
    return raw
        .map((value) => labels[value.toString()])
        .whereType<String>()
        .toSet()
        .toList();
  }

  Widget _contributionPrompt(Map<String, dynamic> place) {
    final aggregate = _aggregateProfiles(_profiles(place));
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
    final complete = pending.isEmpty;
    final lastVerified = _trust(place)?.lastVerifiedAt;
    final daysSinceVerification = lastVerified == null
        ? null
        : DateTime.now().difference(lastVerified.toLocal()).inDays;
    final stale = daysSinceVerification == null || daysSinceVerification > 30;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1D9A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8B8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  complete ? Icons.update_rounded : Icons.travel_explore,
                  color: const Color(0xFF9A6710),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  complete && stale
                      ? 'Este lugar necesita una actualización'
                      : complete
                      ? '¿Sigue igual cuando lo visites?'
                      : 'Ayuda a completar este lugar',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            complete && stale
                ? 'La última comprobación tiene ${daysSinceVerification == null ? 'fecha pendiente' : '$daysSinceVerification días'}. Confirma acceso, estado o una fotografía reciente desde el lugar.'
                : complete
                ? 'Confirma que el acceso y el estado continúan vigentes, o añade una fotografía reciente.'
                : 'Todavía falta confirmar ${pending.join(', ')}. Tu observación desde el lugar mejora la ficha para todos.',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openContribution(place),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9A6710),
              ),
              icon: Icon(
                complete
                    ? Icons.fact_check_outlined
                    : Icons.add_a_photo_outlined,
              ),
              label: Text(
                complete ? 'Confirmar información' : 'Completar ficha',
              ),
            ),
          ),
        ],
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

  String _displayName(Map<String, dynamic> place) {
    return titleCaseUserText(
      place['nombre']?.toString(),
      fallback: 'Descubrimiento',
    );
  }

  String _category(Map<String, dynamic> place) {
    return sentenceCaseUserText(
      place['categoria_ia']?.toString(),
      fallback: 'Lugar natural',
    );
  }

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

  Widget _sourceClarityCard(Map<String, dynamic> place) {
    final trust = _trust(place);
    final supporters = trust?.independentSupporters ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2D7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: Color(0xFF7655A6)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cómo interpretar esta ficha',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sourceRow(
            Icons.people_alt_outlined,
            'Información comunitaria',
            '$supporters ${supporters == 1 ? 'persona independiente respalda' : 'personas independientes respaldan'} la evidencia y las condiciones observadas.',
            const Color(0xFF7655A6),
          ),
          const SizedBox(height: 10),
          _sourceRow(
            Icons.verified_outlined,
            'Registro oficial',
            'Este descubrimiento todavía no figura como registro oficial MINCETUR. RutaAmiga lo mantiene claramente diferenciado.',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _sourceRow(IconData icon, String title, String detail, Color color) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _communityTimeline(Map<String, dynamic> place) {
    final updates = _updates(place).reversed.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evolución del lugar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Observaciones recientes que mantienen vigente esta ficha.',
          style: TextStyle(color: AppColors.textLight, fontSize: 11),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < updates.length; index++)
          _timelineUpdate(updates[index], index == updates.length - 1),
      ],
    );
  }

  Widget _timelineUpdate(Map<String, dynamic> update, bool last) {
    final answers = update['answers'] is Map
        ? Map<String, dynamic>.from(update['answers'] as Map)
        : const <String, dynamic>{};
    final labels = <String>[];
    if (answers['place_state'] != null) labels.add('estado confirmado');
    if (answers['access_type'] != null) labels.add('acceso actualizado');
    if (answers['services'] is List &&
        (answers['services'] as List).isNotEmpty) {
      labels.add('servicios observados');
    }
    final rawDate = update['created_at']?.toString();
    final date = rawDate == null ? null : DateTime.tryParse(rawDate)?.toLocal();
    final dateLabel = date == null
        ? 'Fecha pendiente'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                size: 15,
                color: AppColors.primary,
              ),
            ),
            if (!last)
              Container(width: 2, height: 42, color: const Color(0xFFDCE7E2)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  labels.isEmpty
                      ? 'Aporte incorporado a la ficha.'
                      : labels.join(' · '),
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
