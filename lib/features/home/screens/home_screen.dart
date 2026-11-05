import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/widgets/first_run_guide.dart';
import '../../../core/widgets/main_navigation_bar.dart';
import '../../auth/screens/login_screen.dart';
import '../../places/models/tourist_place_model.dart';
import '../../places/screens/map_screen.dart';
import '../../places/screens/evidence_hub_screen.dart';
import '../../places/screens/tourist_place_detail_screen.dart';
import '../../places/services/google_places_service.dart';
import '../../places/services/exploration_context_service.dart';
import '../../places/services/report_place_service.dart';
import '../../places/services/tourist_place_service.dart';
import '../../places/services/weather_service.dart';
import '../../places/widgets/exploration_area_picker.dart';
import '../../profile/services/travel_library_service.dart';
import '../../routes/services/active_route_service.dart';
import '../../routes/screens/suggested_routes_screen.dart';
import '../../routes/widgets/active_route_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _placeService = TouristPlaceService();
  final _photos = GooglePlacesService();
  final _reports = ReportPlaceService();
  final _weatherService = WeatherService();
  final ActiveRouteService _activeRoute = ActiveRouteService.instance;
  Timer? _clock;
  double? _exploreLatitude;
  double? _exploreLongitude;
  List<TouristPlaceModel> _places = [];
  Map<String, dynamic>? _communityDiscovery;
  Map<String, dynamic>? _weather;
  Map<String, dynamic>? _presence;
  Map<String, dynamic>? _latestContribution;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _activeRoute.addListener(_activeRouteChanged);
    unawaited(_activeRoute.restore());
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(showFirstRunGuideIfNeeded(context));
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _activeRoute.removeListener(_activeRouteChanged);
    super.dispose();
  }

  void _activeRouteChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _continueActiveRoute() async {
    final route = _activeRoute.route;
    if (route == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SuggestedRouteDetailScreen(route: route, activeMode: true),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      await ExplorationContextService.instance.restore();
      final position = await LocationService.getCurrentLocation();
      final area = ExplorationContextService.instance.area;
      final latitude = area?.latitude ?? position.latitude;
      final longitude = area?.longitude ?? position.longitude;
      final results = await Future.wait<dynamic>([
        _placeService.obtenerLugaresCercanos(
          latitud: latitude,
          longitud: longitude,
          radio: area?.radius ?? 30000,
        ),
        PresenceService.instance
            .recent(limit: 5)
            .catchError((_) => <Map<String, dynamic>>[]),
        _reports
            .obtenerReportesCercanos(
              latitud: latitude,
              longitud: longitude,
              radio: area?.radius ?? 30000,
            )
            .catchError((_) => <Map<String, dynamic>>[]),
        _weatherService
            .forecast(latitude: latitude, longitude: longitude)
            .catchError((_) => <String, dynamic>{}),
        _reports
            .obtenerMisAportes(limit: 10)
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final placesData = results[0] as List<Map<String, dynamic>>;
      final presence = results[1] as List<Map<String, dynamic>>;
      final discoveries = (results[2] as List<Map<String, dynamic>>)
          .where(_isPublicDiscovery)
          .toList();
      final weather = results[3] as Map<String, dynamic>;
      final contributions = results[4] as List<Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _exploreLatitude = latitude;
        _exploreLongitude = longitude;
        _places = placesData
            .map(TouristPlaceModel.fromSupabase)
            .where((place) => place.latitud != 0 && place.longitud != 0)
            .take(12)
            .toList();
        _presence = presence.firstOrNull;
        _communityDiscovery = discoveries.firstOrNull;
        _weather = weather.isEmpty ? null : weather;
        _latestContribution = contributions.firstOrNull;
        _loading = false;
        _message = null;
      });
    } on BackendApiException catch (error) {
      if (error.statusCode == 401) {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message =
              'No pudimos cargar lugares cercanos. Desliza para reintentar.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MainNavigationBar(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(child: _topBar()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(child: _searchEntry()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 9),
                sliver: const SliverToBoxAdapter(
                  child: Text(
                    'Lo esencial cerca de ti',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _nearbyEssentials()),
              ),
              if (_activeRoute.route != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: ActiveRouteCard(
                      route: _activeRoute.route!,
                      onContinue: _continueActiveRoute,
                      compact: true,
                    ),
                  ),
                ),
              if (!_loading && _activeRoute.route == null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(child: _nextActionCard()),
                ),
              if (_loading)
                const SliverToBoxAdapter(child: _HomeLoadingSkeleton())
              else if (_places.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  sliver: SliverToBoxAdapter(child: _emptyCard()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _featuredPlace(_places.first),
                  ),
                ),
              if (!_loading && _places.length > 1) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sigue explorando',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _open(const MapScreen()),
                          child: const Text('Ver mapa'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 176,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: (_places.length - 1).clamp(0, 5),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) =>
                          _compactPlaceCard(_places[index + 1]),
                    ),
                  ),
                ),
              ],
              if (!_loading) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Viaja a tu manera',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _travelStyles()),
                if (_communityDiscovery != null) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Perú por descubrir',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: 142,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _communityCard(_communityDiscovery!),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_presenceRemaining != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _compactPresenceReminder(),
                    ),
                  ),
              ],
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
                sliver: SliverToBoxAdapter(child: _contributionLink()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final area = ExplorationContextService.instance.area;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              if (await showExplorationAreaPicker(context) && mounted) {
                await _load();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTÁS EXPLORANDO',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          area == null
                              ? 'Cerca de mi ubicación'
                              : '${area.name} · ${area.scope}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 21,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Ver clima',
          onPressed: _showWeather,
          style: IconButton.styleFrom(
            minimumSize: const Size(50, 50),
            backgroundColor: const Color(0xFFE4F0F4),
            foregroundColor: const Color(0xFF27718A),
          ),
          icon: const Icon(Icons.cloud_outlined, size: 24),
        ),
      ],
    );
  }

  Widget _searchEntry() => InkWell(
    onTap: _searchNearby,
    borderRadius: BorderRadius.circular(16),
    child: Ink(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buscar un lugar en esta zona',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 18),
        ],
      ),
    ),
  );

  double? _distanceTo(TouristPlaceModel place) =>
      _exploreLatitude == null || _exploreLongitude == null
      ? null
      : Geolocator.distanceBetween(
              _exploreLatitude!,
              _exploreLongitude!,
              place.latitud,
              place.longitud,
            ) /
            1000;

  void _openPlace(TouristPlaceModel place) {
    final distance = _distanceTo(place);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TouristPlaceDetailScreen(place: place, distance: distance ?? 0),
      ),
    );
  }

  Widget _placePhoto(TouristPlaceModel place) => FutureBuilder<String?>(
    future: _photos.getTouristPhotoUrl(
      name: place.nombre,
      lat: place.latitud,
      lng: place.longitud,
    ),
    builder: (_, snapshot) => snapshot.data == null
        ? const ColoredBox(
            color: AppColors.primarySoft,
            child: Icon(
              Icons.landscape_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          )
        : Image.network(
            snapshot.data!,
            headers: _photos.photoHeaders,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: AppColors.primarySoft,
              child: Icon(Icons.landscape, color: AppColors.primary),
            ),
          ),
  );

  Widget _featuredPlace(TouristPlaceModel place) {
    final distance = _distanceTo(place);
    return InkWell(
      onTap: () => _openPlace(place),
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        height: 326,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: _placePhoto(place),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x10000000),
                    Color(0x18000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, .42, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'DESTINO OFICIAL',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .9),
                  foregroundColor: AppColors.primaryDark,
                ),
                onPressed: () => _toggleFavorite(place),
                icon: const Icon(Icons.favorite_border_rounded, size: 19),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UNA IDEA PARA HOY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          place.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            height: 1.03,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${place.provincia}${distance == null ? '' : ' · ${distance.toStringAsFixed(1)} km'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      color: AppColors.primaryDark,
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

  Widget _compactPlaceCard(TouristPlaceModel place) => InkWell(
    onTap: () => _openPlace(place),
    borderRadius: BorderRadius.circular(22),
    child: Ink(
      width: 170,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _placePhoto(place),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [.35, 1],
              ),
            ),
          ),
          Positioned(
            left: 13,
            right: 13,
            bottom: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.provincia,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _toggleFavorite(TouristPlaceModel place) async {
    final added = await TravelLibraryService.instance.toggleFavorite(place);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Guardado en tus favoritos.' : 'Eliminado de tus favoritos.',
        ),
      ),
    );
  }

  bool _isPublicDiscovery(Map<String, dynamic> report) {
    final status = (report['estado_validacion'] ?? report['status'])
        ?.toString();
    return const {
      'validated',
      'approved',
      'validated_satellite',
    }.contains(status);
  }

  Duration? get _presenceRemaining {
    final expiry = DateTime.tryParse(
      _presence?['expires_at']?.toString() ?? '',
    )?.toLocal();
    final remaining = expiry?.difference(DateTime.now());
    return remaining != null && !remaining.isNegative ? remaining : null;
  }

  Widget _compactPresenceReminder() {
    final remaining = _presenceRemaining!;
    final minutes = remaining.inMinutes % 60;
    return InkWell(
      onTap: () => _open(const EvidenceHubScreen()),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F1ED),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 17,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Visita activa · ${remaining.inHours} h ${minutes.toString().padLeft(2, '0')} min para realizar un aporte',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _travelStyles() {
    const styles = [
      (Icons.forest_outlined, 'Naturaleza', 'nature', Color(0xFFDDE9D7)),
      (
        Icons.auto_awesome_outlined,
        'Joyas ocultas',
        'discoveries',
        Color(0xFFE5DDF0),
      ),
      (Icons.verified_outlined, 'Clásicos', 'official', Color(0xFFDCEAF1)),
      (Icons.explore_outlined, 'Variado', 'mixed', Color(0xFFF3DFCB)),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final style = styles[index];
          return InkWell(
            onTap: () =>
                _open(SuggestedRoutesScreen(initialExperience: style.$3)),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 126,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: style.$4,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(style.$1, color: AppColors.primaryDark, size: 23),
                  const SizedBox(height: 9),
                  Text(
                    style.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weatherDescription(int code) {
    if (code == 0) return 'Cielo despejado';
    if (code <= 3) return 'Parcialmente nublado';
    if (code == 45 || code == 48) return 'Neblina';
    if (code <= 67) return 'Probabilidad de lluvia';
    if (code <= 77) return 'Nieve en la zona';
    if (code <= 82) return 'Lluvias intermitentes';
    return 'Tormentas posibles';
  }

  IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_outlined;
    if (code <= 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_outlined;
    return Icons.water_drop_outlined;
  }

  Future<void> _showWeather() async {
    final weather = _weather;
    if (weather == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todavía estamos consultando el clima de esta zona.'),
        ),
      );
      return;
    }
    final current = Map<String, dynamic>.from(
      (weather['current'] as Map?) ?? const {},
    );
    final daily = Map<String, dynamic>.from(
      (weather['daily'] as Map?) ?? const {},
    );
    final temperature = (current['temperature_2m'] as num?)?.round();
    final apparent = (current['apparent_temperature'] as num?)?.round();
    final wind = (current['wind_speed_10m'] as num?)?.round();
    final code = (current['weather_code'] as num?)?.round() ?? 0;
    final rainValues = daily['precipitation_probability_max'];
    final rain = rainValues is List && rainValues.isNotEmpty
        ? (rainValues.first as num?)?.round()
        : null;
    final maxValues = daily['temperature_2m_max'];
    final minValues = daily['temperature_2m_min'];
    final codeValues = daily['weather_code'];
    final area =
        ExplorationContextService.instance.area?.name ?? 'Tu ubicación';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4F0F4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _weatherIcon(code),
                      color: const Color(0xFF27718A),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clima en $area',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _weatherDescription(code),
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  if (temperature != null)
                    Text(
                      '$temperature°',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _weatherMetric(
                      Icons.thermostat_rounded,
                      'Sensación',
                      apparent == null ? '—' : '$apparent °C',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _weatherMetric(
                      Icons.water_drop_outlined,
                      'Lluvia',
                      rain == null ? '—' : '$rain%',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _weatherMetric(
                      Icons.air_rounded,
                      'Viento',
                      wind == null ? '—' : '$wind km/h',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Próximos días',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var index = 0; index < 3; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _forecastDay(
                        index == 0
                            ? 'Hoy'
                            : index == 1
                            ? 'Mañana'
                            : 'Después',
                        codeValues is List && codeValues.length > index
                            ? (codeValues[index] as num?)?.round() ?? 0
                            : 0,
                        maxValues is List && maxValues.length > index
                            ? (maxValues[index] as num?)?.round()
                            : null,
                        minValues is List && minValues.length > index
                            ? (minValues[index] as num?)?.round()
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Pronóstico referencial. En montaña el clima puede cambiar rápidamente.',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherMetric(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF27718A), size: 19),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 9),
        ),
      ],
    ),
  );

  Widget _forecastDay(String label, int code, int? maximum, int? minimum) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE1E9E6)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Icon(_weatherIcon(code), color: const Color(0xFF27718A), size: 21),
            const SizedBox(height: 7),
            Text(
              maximum == null || minimum == null
                  ? '—'
                  : '$maximum° / $minimum°',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );

  bool _profileCompleted(Map<String, dynamic> item) {
    final events = item['processing_events'] as List? ?? const [];
    return events.any((event) {
      if (event is! Map || event['status']?.toString() != 'completed') {
        return false;
      }
      final metadata = event['metadata'];
      return event['stage']?.toString() == 'community_profile' ||
          (metadata is Map &&
              metadata['event_type']?.toString() == 'community_profile');
    });
  }

  Widget _nextActionCard() {
    final contribution = _latestContribution;
    final status = contribution?['status']?.toString();
    late final IconData icon;
    late final Color accent;
    late final String eyebrow;
    late final String title;
    late final String description;
    late final String actionLabel;
    late final VoidCallback action;

    if (contribution != null &&
        status == 'validated' &&
        !_profileCompleted(contribution)) {
      icon = Icons.fact_check_outlined;
      accent = const Color(0xFF9A5A00);
      eyebrow = 'TU DESCUBRIMIENTO FUE VALIDADO';
      title = 'Completa la ficha del lugar';
      description =
          'Responde unas preguntas breves para que otras personas sepan cómo llegar y qué encontrar.';
      actionLabel = 'Completar ahora';
      action = () => _openAndReload(const EvidenceHubScreen());
    } else if (contribution != null &&
        const {'pending', 'processing_ai', 'processing_gis'}.contains(status)) {
      icon = Icons.auto_awesome_rounded;
      accent = const Color(0xFF2874A6);
      eyebrow = 'VALIDACIÓN EN CURSO';
      title = 'Estamos comprobando tu aporte';
      description =
          'Puedes seguir explorando. El resultado aparecerá automáticamente cuando esté listo.';
      actionLabel = 'Ver progreso';
      action = () => _openAndReload(const EvidenceHubScreen());
    } else if (contribution != null &&
        const {'candidate', 'needs_review'}.contains(status)) {
      icon = Icons.rate_review_outlined;
      accent = const Color(0xFF9A6800);
      eyebrow = 'REVISIÓN FINAL';
      title = 'Tu aporte está cerca de publicarse';
      description =
          'La evidencia ya fue analizada y ahora espera la confirmación final de un revisor.';
      actionLabel = 'Ver estado';
      action = () => _openAndReload(const EvidenceHubScreen());
    } else if (contribution != null && status == 'duplicate') {
      icon = Icons.collections_bookmark_outlined;
      accent = const Color(0xFF7655A6);
      eyebrow = 'APORTE CONSOLIDADO';
      title = 'Tu fotografía reforzó una ficha existente';
      description =
          'La evidencia quedó asociada al lugar correcto y aumenta su respaldo comunitario.';
      actionLabel = 'Ver mis aportes';
      action = () => _openAndReload(const EvidenceHubScreen());
    } else if (_presenceRemaining != null) {
      icon = Icons.add_a_photo_outlined;
      accent = AppColors.primary;
      eyebrow = 'VISITA ACTIVA';
      title = '¿Encontraste algo interesante?';
      description =
          'Tu ubicación reciente puede respaldar una fotografía tomada desde el lugar.';
      actionLabel = 'Realizar aporte';
      action = () => _openAndReload(const EvidenceHubScreen());
    } else if (_communityDiscovery != null) {
      icon = Icons.people_alt_outlined;
      accent = const Color(0xFF7655A6);
      eyebrow = 'CERCA DE TI';
      title = 'Explora un descubrimiento comunitario';
      description =
          'Conoce un lugar corroborado por viajeros o aporta una nueva perspectiva desde campo.';
      actionLabel = 'Ver descubrimientos';
      action = () => _open(const MapScreen(initialLayer: 'rutaamiga'));
    } else {
      icon = Icons.route_outlined;
      accent = AppColors.primary;
      eyebrow = 'IDEA PARA HOY';
      title = 'Planifica una salida a tu medida';
      description =
          'Indica cuánto tiempo tienes y RutaAmiga buscará un recorrido compatible.';
      actionLabel = 'Crear una ruta';
      action = () => _open(const SuggestedRoutesScreen());
    }

    return Semantics(
      button: true,
      label: '$title. $actionLabel',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            action();
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: .18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: TextStyle(
                          color: accent,
                          fontSize: 8,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        actionLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nearbyEssentials() {
    const items = [
      (Icons.restaurant_outlined, 'Comer', 'restaurant'),
      (Icons.bed_outlined, 'Dormir', 'lodging'),
      (Icons.local_pharmacy_outlined, 'Farmacia', 'pharmacy'),
      (Icons.local_gas_station_outlined, 'Combustible', 'gas_station'),
    ];
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _open(MapScreen(initialLayer: items[index].$3)),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E9E5)),
                ),
                child: Column(
                  children: [
                    Icon(items[index].$1, color: AppColors.primary, size: 20),
                    const SizedBox(height: 7),
                    Text(
                      items[index].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _communityCard(Map<String, dynamic> discovery) {
    final photoUrl = (discovery['foto_url'] ?? discovery['photo_url'])
        ?.toString();
    final name = discovery['nombre']?.toString() ?? 'Nuevo descubrimiento';
    return InkWell(
      onTap: () => _open(const MapScreen()),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: 286,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0x33000000), Color(0xE6000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 17,
              right: 17,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESCUBIERTO POR LA COMUNIDAD',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
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

  Widget _emptyCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(Icons.travel_explore, color: AppColors.primary, size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _message ??
                'Aún no encontramos atractivos cercanos. Prueba explorando otra zona.',
            style: const TextStyle(color: AppColors.textLight),
          ),
        ),
      ],
    ),
  );

  Widget _contributionLink() => Center(
    child: TextButton.icon(
      onPressed: () => _open(const EvidenceHubScreen()),
      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
      label: const Text('¿Encontraste un lugar nuevo? Compártelo'),
    ),
  );

  Future<void> _searchNearby() async {
    final selected = await showSearch<TouristPlaceModel?>(
      context: context,
      delegate: _NearbyPlaceSearchDelegate(_places),
    );
    if (selected != null && mounted) _openPlace(selected);
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _openAndReload(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
    child: Column(
      children: [
        _box(height: 326, radius: 28),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _box(height: 150, radius: 22)),
            const SizedBox(width: 12),
            Expanded(child: _box(height: 150, radius: 22)),
          ],
        ),
      ],
    ),
  );

  Widget _box({required double height, required double radius}) =>
      TweenAnimationBuilder<double>(
        tween: Tween(begin: .55, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (_, opacity, __) => Opacity(
          opacity: opacity,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EDE9),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      );
}

class _NearbyPlaceSearchDelegate extends SearchDelegate<TouristPlaceModel?> {
  _NearbyPlaceSearchDelegate(this.places);

  final List<TouristPlaceModel> places;

  @override
  String get searchFieldLabel => 'Buscar en esta zona';

  List<TouristPlaceModel> get _results {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return places;
    return places.where((place) {
      return '${place.nombre} ${place.categoria} ${place.distrito} ${place.provincia} ${place.departamento}'
          .toLowerCase()
          .contains(normalized);
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Limpiar',
        onPressed: () => query = '',
        icon: const Icon(Icons.close_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: 'Volver',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _resultList();

  @override
  Widget buildSuggestions(BuildContext context) => _resultList();

  Widget _resultList() {
    final results = _results;
    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No encontramos ese lugar en la zona seleccionada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final place = results[index];
        return ListTile(
          onTap: () => close(context, place),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.place_outlined, color: AppColors.primary),
          ),
          title: Text(
            place.nombre,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('${place.provincia}, ${place.departamento}'),
          trailing: const Icon(Icons.arrow_outward_rounded, size: 18),
        );
      },
    );
  }
}
