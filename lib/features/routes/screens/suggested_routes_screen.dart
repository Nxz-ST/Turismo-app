import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/widgets/main_navigation_bar.dart';
import '../../../core/widgets/presence_lifecycle.dart';
import '../../places/services/google_routes_service.dart';
import '../../places/services/google_places_service.dart';
import '../../places/services/exploration_context_service.dart';
import '../../places/services/weather_service.dart';
import '../../places/widgets/exploration_area_picker.dart';
import '../../profile/screens/my_trip_screen.dart';
import '../../profile/services/travel_library_service.dart';
import '../services/active_route_service.dart';
import '../services/itinerary_service.dart';
import '../services/route_visit_service.dart';
import '../services/route_readiness_service.dart';
import '../widgets/active_route_card.dart';
import 'custom_route_builder_screen.dart';

class SuggestedRoutesScreen extends StatefulWidget {
  const SuggestedRoutesScreen({
    super.key,
    this.initialExperience = 'mixed',
    this.initialDurationMinutes = 300,
    this.initialIntent = 'nearby',
  });

  final String initialExperience;
  final int initialDurationMinutes;
  final String initialIntent;

  @override
  State<SuggestedRoutesScreen> createState() => _SuggestedRoutesScreenState();
}

class _SuggestedRoutesScreenState extends State<SuggestedRoutesScreen> {
  final ItineraryService _service = ItineraryService();
  late Future<List<Map<String, dynamic>>> _future;
  late int _durationMinutes;
  late String _experience;
  String _travelMode = 'driving';
  bool _plannerExpanded = false;
  late String _intent;
  int _maxDetourMinutes = 20;
  final ActiveRouteService _activeRoute = ActiveRouteService.instance;
  int _savedTripStops = 0;

  @override
  void initState() {
    super.initState();
    _durationMinutes = widget.initialDurationMinutes;
    _experience = widget.initialExperience;
    _intent = widget.initialIntent;
    _future = _load();
    _activeRoute.addListener(_activeRouteChanged);
    unawaited(_activeRoute.restore());
    unawaited(_restoreSavedTrip());
  }

  @override
  void dispose() {
    _activeRoute.removeListener(_activeRouteChanged);
    super.dispose();
  }

  void _activeRouteChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openActiveRoute() async {
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

  Future<List<Map<String, dynamic>>> _load() async {
    final position = await LocationService.getCurrentLocation();
    await ExplorationContextService.instance.restore();
    final area = ExplorationContextService.instance.area;
    unawaited(
      PresenceService.instance.recordPosition(position, source: 'route'),
    );
    return _service.suggestions(
      latitude: _intent == 'corridor'
          ? position.latitude
          : area?.latitude ?? position.latitude,
      longitude: _intent == 'corridor'
          ? position.longitude
          : area?.longitude ?? position.longitude,
      radius: area?.radius ?? 30000,
      durationMinutes: _durationMinutes,
      experience: _experience,
      travelMode: _travelMode,
      intent: _intent,
      destinationLatitude: _intent == 'corridor' ? area?.latitude : null,
      destinationLongitude: _intent == 'corridor' ? area?.longitude : null,
      destinationName: _intent == 'corridor' ? area?.name : null,
      maxDetourMinutes: _maxDetourMinutes,
    );
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  void _createRoute() {
    final next = _load();
    setState(() {
      _future = next;
      _plannerExpanded = false;
    });
  }

  Future<void> _showRouteOptionsSheet() async {
    var duration = _durationMinutes;
    var experience = _experience;
    var travelMode = _travelMode;
    var intent = _intent;
    var maxDetour = _maxDetourMinutes;
    final selection = await showModalBottomSheet<_RouteOptionSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajusta tu recorrido',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Elige cómo quieres viajar y actualizaremos las opciones.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 20),
                  const _PlannerLabel('Tiempo disponible'),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in const [
                        (120, '2 horas'),
                        (300, 'Medio día'),
                        (600, 'Día completo'),
                      ])
                        ChoiceChip(
                          label: Text(option.$2),
                          selected: duration == option.$1,
                          onSelected: (_) =>
                              setSheetState(() => duration = option.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _PlannerLabel('Tipo de recorrido'),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in const [
                        ('nearby', 'Cerca de mí'),
                        ('corridor', 'En mi camino'),
                        ('day', 'Plan para hoy'),
                        ('discoveries', 'Descubrimientos'),
                      ])
                        ChoiceChip(
                          label: Text(option.$2),
                          selected: intent == option.$1,
                          onSelected: (_) =>
                              setSheetState(() => intent = option.$1),
                        ),
                    ],
                  ),
                  if (intent == 'corridor') ...[
                    const SizedBox(height: 14),
                    const _PlannerLabel('Desvío máximo'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final value in const [10, 20, 40])
                          ChoiceChip(
                            label: Text('$value min'),
                            selected: maxDetour == value,
                            onSelected: (_) =>
                                setSheetState(() => maxDetour = value),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  const _PlannerLabel('Experiencia'),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in const [
                        ('mixed', 'Recomendada'),
                        ('nature', 'Naturaleza'),
                        ('official', 'Oficiales'),
                        ('discoveries', 'Descubrimientos'),
                      ])
                        ChoiceChip(
                          label: Text(option.$2),
                          selected: experience == option.$1,
                          onSelected: (_) =>
                              setSheetState(() => experience = option.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _PlannerLabel('Cómo te moverás'),
                  const SizedBox(height: 9),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'driving',
                        icon: Icon(Icons.directions_car_outlined),
                        label: Text('Auto'),
                      ),
                      ButtonSegment(
                        value: 'walking',
                        icon: Icon(Icons.directions_walk_rounded),
                        label: Text('A pie'),
                      ),
                    ],
                    selected: {travelMode},
                    onSelectionChanged: (values) =>
                        setSheetState(() => travelMode = values.first),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        _RouteOptionSelection(
                          durationMinutes: duration,
                          experience: experience,
                          travelMode: travelMode,
                          intent: intent,
                          maxDetourMinutes: maxDetour,
                        ),
                      ),
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Buscar nuevas rutas'),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        const _RouteOptionSelection(changeDestination: true),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Cambiar destino'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (selection == null || !mounted) return;
    if (selection.changeDestination) {
      if (await showExplorationAreaPicker(context) && mounted) {
        await _reload();
      }
      return;
    }
    if (selection.intent == 'corridor' &&
        ExplorationContextService.instance.area == null) {
      final changed = await showExplorationAreaPicker(context);
      if (!changed || !mounted) return;
    }
    setState(() {
      _durationMinutes = selection.durationMinutes!;
      _experience = selection.experience!;
      _travelMode = selection.travelMode!;
      _intent = selection.intent!;
      _maxDetourMinutes = selection.maxDetourMinutes!;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MainNavigationBar(currentIndex: 2),
      appBar: AppBar(
        title: Text(
          _activeRoute.route == null ? 'Rutas para ti' : 'Tu recorrido',
        ),
      ),
      body: _activeRoute.route != null
          ? _activeRouteOverview(_activeRoute.route!)
          : Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _EmptyRoutes(
                          title: 'No pudimos crear rutas',
                          message: _friendlyRouteError(snapshot.error),
                          onRetry: _reload,
                        );
                      }
                      final routes = snapshot.data ?? const [];
                      if (routes.isEmpty) {
                        return _EmptyRoutes(
                          title: _durationMinutes <= 120
                              ? 'No hay una ruta segura de 2 horas'
                              : 'Aún no hay rutas compatibles',
                          message: _durationMinutes <= 120
                              ? 'Los atractivos naturales de esta zona necesitan más tiempo de traslado y actividad. Prueba “Medio día”; los nevados solo aparecerán en planes de día completo.'
                              : 'Prueba ampliar el tiempo, cambiar el destino o elegir otra experiencia.',
                          actionLabel: 'Cambiar opciones',
                          onRetry: _showRouteOptionsSheet,
                          secondaryActionLabel: 'Crear mi propia ruta',
                          onSecondaryAction: _openRouteCreator,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _destinationHeader(routes),
                            const SizedBox(height: 22),
                            const Text(
                              'La mejor opción para tu plan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Equilibra tiempo, distancia y tipo de experiencia.',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _RouteCard(route: routes.first, featured: true),
                            if (routes.length > 1) ...[
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Otras formas de explorar',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${routes.length - 1} alternativas',
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              for (final route in routes.skip(1)) ...[
                                _RouteCard(route: route),
                                const SizedBox(height: 12),
                              ],
                            ],
                            if (routes.length < 3) ...[
                              const SizedBox(height: 12),
                              _RouteAvailabilityNote(routeCount: routes.length),
                            ],
                            const SizedBox(height: 12),
                            _planner(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _activeRouteOverview(Map<String, dynamic> route) {
    final stops = (route['stops'] as List? ?? const []);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text(
          'Tu viaje está en marcha',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          stops.length == 1
              ? 'Continúa hacia tu próxima parada.'
              : 'Tienes ${stops.length} paradas en este recorrido. Continúa desde donde lo dejaste.',
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ActiveRouteCard(route: route, onContinue: _openActiveRoute),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFCFE7DE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.explore_outlined, color: AppColors.primary, size: 25),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continúa cuando estés listo',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'RutaAmiga conservará tu avance y te guiará hacia la siguiente parada.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _destinationHeader(List<Map<String, dynamic>> routes) {
    final area = ExplorationContextService.instance.area;
    final stops = routes.isEmpty
        ? const <Map<String, dynamic>>[]
        : (routes.first['stops'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
    final province = stops
        .map((stop) => stop['province']?.toString() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => 'tu destino');
    final displayPlace = area?.name ?? _titleCase(province);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explora $displayPlace',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Elige una ruta y adapta el plan a tu tiempo.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () async {
                if (await showExplorationAreaPicker(context) && mounted) {
                  _reload();
                }
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Cambiar destino',
            ),
          ],
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: _showRouteOptionsSheet,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_durationLabel()} · ${_intentLabel()} · ${_experienceLabel()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Text(
                  'Cambiar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _durationLabel() => switch (_durationMinutes) {
    120 => '2 horas',
    300 => 'Medio día',
    600 => 'Día completo',
    _ => 'Plan flexible',
  };

  String _intentLabel() => switch (_intent) {
    'corridor' => 'En mi camino',
    'day' => 'Plan para hoy',
    'discoveries' => 'Descubrimientos',
    _ => 'Cerca de mí',
  };

  String _experienceLabel() => switch (_experience) {
    'nature' => 'Naturaleza',
    'official' => 'Oficiales',
    'discoveries' => 'Nuevos lugares',
    _ => 'Recomendada',
  };

  String _friendlyRouteError(Object? error) {
    final detail = error?.toString() ?? '';
    debugPrint('Error cargando rutas: $detail');
    final normalized = detail.toLowerCase();
    if (normalized.contains('socketexception') ||
        normalized.contains('connection refused') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection timed out')) {
      return 'No pudimos conectarnos con RutaAmiga. Revisa tu conexión e inténtalo nuevamente.';
    }
    return 'Ocurrió un problema al preparar tus recomendaciones. Inténtalo nuevamente en unos segundos.';
  }

  // Se conserva como base del selector interno; la pantalla principal usa
  // ahora el resumen compacto y abre las opciones en una hoja inferior.
  // ignore: unused_element
  Widget _intentSelector() {
    const modes = [
      ('nearby', 'Cerca de mí', 'Lugares próximos', Icons.near_me_outlined),
      (
        'corridor',
        'En mi camino',
        'Paradas rumbo a un destino',
        Icons.alt_route_rounded,
      ),
      ('day', 'Plan para hoy', 'Según tu tiempo', Icons.wb_sunny_outlined),
      (
        'discoveries',
        'Descubrimientos',
        'Nuevos lugares validados',
        Icons.auto_awesome_outlined,
      ),
      ('custom', 'Mi ruta', 'Elige cada detalle', Icons.tune_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo quieres viajar?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Elige una intención y ajustaremos el recorrido.',
          style: TextStyle(color: AppColors.textLight, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final mode = modes[index];
              final selected =
                  _intent == mode.$1 ||
                  (mode.$1 == 'custom' && _plannerExpanded);
              return InkWell(
                onTap: () => _selectIntent(mode.$1),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFE1EAE7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode.$4,
                        color: selected ? Colors.white : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        mode.$2,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                modes
                    .firstWhere(
                      (mode) =>
                          mode.$1 == (_plannerExpanded ? 'custom' : _intent),
                    )
                    .$3,
                style: const TextStyle(
                  color: AppColors.textLight,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (_intent == 'corridor') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Desvío máximo',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              const SizedBox(width: 10),
              for (final value in const [10, 20, 40]) ...[
                ChoiceChip(
                  label: Text('$value min'),
                  selected: _maxDetourMinutes == value,
                  onSelected: (_) {
                    setState(() => _maxDetourMinutes = value);
                    _reload();
                  },
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _selectIntent(String value) async {
    if (value == 'custom') {
      setState(() => _plannerExpanded = true);
      return;
    }
    if (value == 'corridor' &&
        ExplorationContextService.instance.area == null) {
      final changed = await showExplorationAreaPicker(context);
      if (!changed ||
          !mounted ||
          ExplorationContextService.instance.area == null) {
        return;
      }
    }
    setState(() {
      _intent = value;
      _plannerExpanded = false;
      if (value == 'day') _durationMinutes = 600;
      if (value == 'discoveries') _experience = 'discoveries';
      if (value == 'nearby') _experience = 'mixed';
    });
    _reload();
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Widget _planner() {
    if (!_plannerExpanded) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1EAE7)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi ruta personalizada',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _savedTripStops > 0
                        ? '$_savedTripStops paradas guardadas · añade o cambia lugares.'
                        : 'Elige, ordena y administra tus propias paradas.',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _openRouteCreator,
              child: Text(_savedTripStops > 0 ? 'Editar' : 'Crear'),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1EAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personaliza tu recorrido',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Elige el tiempo y el tipo de recorrido que prefieres.',
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const _PlannerLabel('Tiempo disponible'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choice('2 horas', _durationMinutes == 120, () {
                setState(() => _durationMinutes = 120);
              }),
              _choice('Medio día', _durationMinutes == 300, () {
                setState(() => _durationMinutes = 300);
              }),
              _choice('Día completo', _durationMinutes == 600, () {
                setState(() => _durationMinutes = 600);
              }),
            ],
          ),
          const SizedBox(height: 17),
          const _PlannerLabel('Experiencia'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choice('Recomendada', _experience == 'mixed', () {
                setState(() => _experience = 'mixed');
              }),
              _choice('Naturaleza', _experience == 'nature', () {
                setState(() => _experience = 'nature');
              }),
              _choice('Oficiales', _experience == 'official', () {
                setState(() => _experience = 'official');
              }),
              _choice('Descubrimientos', _experience == 'discoveries', () {
                setState(() => _experience = 'discoveries');
              }),
            ],
          ),
          const SizedBox(height: 17),
          const _PlannerLabel('Cómo te moverás'),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _transportChoice(
                  Icons.directions_car_outlined,
                  'Auto',
                  'driving',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _transportChoice(
                  Icons.directions_walk_rounded,
                  'A pie',
                  'walking',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _createRoute,
              icon: const Icon(Icons.route_rounded),
              label: const Text('Crear mi ruta'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRouteCreator() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CustomRouteBuilderScreen()),
    );
    if (saved == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyTripScreen()),
      );
    }
    await _restoreSavedTrip();
  }

  Future<void> _restoreSavedTrip() async {
    final places = await TravelLibraryService.instance.trip();
    if (!mounted) return;
    setState(() => _savedTripStops = places.length);
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );

  Widget _transportChoice(IconData icon, String label, String value) {
    final selected = _travelMode == value;
    return InkWell(
      onTap: () => setState(() => _travelMode = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE1EAE7),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerLabel extends StatelessWidget {
  const _PlannerLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
  );
}

class _RouteAvailabilityNote extends StatelessWidget {
  const _RouteAvailabilityNote({required this.routeCount});

  final int routeCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7EA),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFF2DFC0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFFC67B18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            routeCount == 1
                ? 'Hay un solo circuito diferente que cumple este tiempo. No repetimos las mismas paradas con otro nombre; cambia las opciones o arma tu propia ruta.'
                : 'Encontramos $routeCount circuitos realmente distintos. Puedes ampliar el tiempo o crear uno con tus lugares favoritos.',
            style: const TextStyle(
              color: Color(0xFF705329),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RouteCard extends StatefulWidget {
  const _RouteCard({required this.route, this.featured = false});
  final Map<String, dynamic> route;
  final bool featured;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  final GooglePlacesService _photos = GooglePlacesService();
  Future<String?>? _photoFuture;
  String? _directPhotoUrl;

  Map<String, dynamic> get route => widget.route;

  @override
  void initState() {
    super.initState();
    final stops = (route['stops'] as List? ?? const []);
    if (widget.featured && stops.isNotEmpty) {
      final stop = Map<String, dynamic>.from(stops.first as Map);
      _directPhotoUrl = stop['photo_url']?.toString().trim();
      final latitude = (stop['latitude'] as num?)?.toDouble();
      final longitude = (stop['longitude'] as num?)?.toDouble();
      if ((_directPhotoUrl == null || _directPhotoUrl!.isEmpty) &&
          latitude != null &&
          longitude != null) {
        _photoFuture = _photos.getTouristPhotoUrl(
          name: stop['name']?.toString() ?? 'Atractivo turístico',
          lat: latitude,
          lng: longitude,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = (route['stops'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final minutes =
        int.tryParse(route['duration_minutes']?.toString() ?? '') ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestedRouteDetailScreen(route: route),
        ),
      ),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.featured) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _featuredPhoto(),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 14,
                        bottom: 12,
                        child: Text(
                          'RUTA DESTACADA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _icon(route['kind']?.toString()),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['title']?.toString() ?? 'Ruta sugerida',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route['subtitle']?.toString() ?? '',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metric(
                  Icons.place_outlined,
                  stops.length == 1 ? '1 destino' : '${stops.length} paradas',
                ),
                _metric(Icons.near_me_outlined, '${route['distance_km']} km'),
                _metric(Icons.schedule, _duration(minutes)),
                if (route['requires_special_planning'] == true)
                  _metric(
                    Icons.warning_amber_rounded,
                    'Requiere planificación',
                  ),
                if (stops.any((stop) => stop['source'] == 'community'))
                  _metric(Icons.groups_outlined, 'Incluye comunidad'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    stops.isEmpty
                        ? 'Recorrido listo para explorar'
                        : 'Empieza en ${stops.first['name']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ver recorrido',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _metric(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  static String _duration(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60} h ${minutes % 60} min' : '$minutes min';
  static IconData _icon(String? kind) => switch (kind) {
    'discoveries' => Icons.explore_outlined,
    'nature' => Icons.forest_outlined,
    _ => Icons.near_me_outlined,
  };

  Widget _featuredPhoto() {
    if (_directPhotoUrl != null && _directPhotoUrl!.isNotEmpty) {
      return Image.network(
        _directPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoFallback(),
      );
    }
    return FutureBuilder<String?>(
      future: _photoFuture,
      builder: (_, snapshot) {
        final url = snapshot.data;
        if (url != null && url.isNotEmpty) {
          return Image.network(
            url,
            headers: _photos.photoHeaders,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _photoFallback(),
          );
        }
        return _photoFallback();
      },
    );
  }

  Widget _photoFallback() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF176F69), Color(0xFF6EB6A0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(
      child: Icon(Icons.landscape_rounded, color: Colors.white70, size: 58),
    ),
  );
}

class SuggestedRouteDetailScreen extends StatefulWidget {
  const SuggestedRouteDetailScreen({
    super.key,
    required this.route,
    this.activeMode = false,
  });
  final Map<String, dynamic> route;
  final bool activeMode;

  @override
  State<SuggestedRouteDetailScreen> createState() =>
      _SuggestedRouteDetailScreenState();
}

class _SuggestedRouteDetailScreenState
    extends State<SuggestedRouteDetailScreen> {
  final GoogleRoutesService _routesService = GoogleRoutesService();
  final GooglePlacesService _photos = GooglePlacesService();
  final RouteVisitService _visits = RouteVisitService();
  _RoadRoute? _roadRoute;
  bool _loadingRoute = true;
  String? _routeError;
  int _nextStopIndex = 0;
  bool _routeActive = false;
  bool _checkingArrival = false;
  bool _allowActivePop = false;
  late final Future<Map<String, dynamic>?> _weatherFuture;

  List<Map<String, dynamic>> get _stops =>
      (widget.route['stops'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  String get _travelMode =>
      widget.route['travel_mode']?.toString() ?? 'driving';

  @override
  void initState() {
    super.initState();
    _routeActive = widget.activeMode;
    _weatherFuture = _loadWeather();
    _loadRoadRoute();
    _loadProgress();
    _loadRouteSession();
  }

  String get _progressKey {
    return ActiveRouteService.progressKey(widget.route);
  }

  String get _activeRouteKey => '${_progressKey}_active';

  Future<Map<String, dynamic>?> _loadWeather() async {
    final stops = _stops;
    if (stops.isEmpty) return null;
    try {
      return await WeatherService().forecast(
        latitude: (stops.first['latitude'] as num).toDouble(),
        longitude: (stops.first['longitude'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRouteSession() async {
    await ActiveRouteService.instance.restore();
    if (widget.activeMode &&
        !ActiveRouteService.instance.matches(widget.route)) {
      await ActiveRouteService.instance.start(widget.route);
    }
    if (!mounted) return;
    setState(
      () => _routeActive = ActiveRouteService.instance.matches(widget.route),
    );
  }

  Future<void> _loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getInt(_progressKey) ?? 0;
    if (!mounted) return;
    setState(() => _nextStopIndex = saved.clamp(0, _stops.length));
  }

  Future<void> _completeCurrentStop() async {
    if (_nextStopIndex >= _stops.length) return;
    final next = _nextStopIndex + 1;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_progressKey, next);
    if (!mounted) return;
    setState(() => _nextStopIndex = next);
  }

  Future<void> _resetProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_progressKey);
    await preferences.remove(_activeRouteKey);
    if (ActiveRouteService.instance.matches(widget.route)) {
      await ActiveRouteService.instance.clear();
    }
    if (!mounted) return;
    setState(() {
      _nextStopIndex = 0;
      _routeActive = false;
    });
  }

  Future<void> _loadRoadRoute() async {
    final stops = _stops;
    if (stops.length < 2) {
      if (!mounted) return;
      setState(() => _loadingRoute = false);
      return;
    }

    try {
      final points = <LatLng>[];
      var distanceMeters = 0;
      var durationSeconds = 0;
      for (var index = 0; index < stops.length - 1; index++) {
        final origin = stops[index];
        final destination = stops[index + 1];
        final result = await _routesService.getRoute(
          originLat: (origin['latitude'] as num).toDouble(),
          originLng: (origin['longitude'] as num).toDouble(),
          destinationLat: (destination['latitude'] as num).toDouble(),
          destinationLng: (destination['longitude'] as num).toDouble(),
          travelMode: _travelMode,
        );
        final encoded =
            ((result['polyline'] as Map?)?['encodedPolyline'])?.toString() ??
            '';
        final legPoints = _decodePolyline(encoded);
        if (points.isNotEmpty && legPoints.isNotEmpty) legPoints.removeAt(0);
        points.addAll(legPoints);
        distanceMeters +=
            int.tryParse(result['distanceMeters']?.toString() ?? '') ?? 0;
        durationSeconds += _durationSeconds(result['duration']?.toString());
      }
      if (!mounted) return;
      setState(() {
        _roadRoute = _RoadRoute(
          points: points,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
        );
        _loadingRoute = false;
        _routeError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeError = 'No se pudo calcular el trazado vial en este momento.';
      });
    }
  }

  static int _durationSeconds(String? value) {
    if (value == null) return 0;
    return double.tryParse(value.replaceAll('s', ''))?.round() ?? 0;
  }

  static List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;
    final positions = stops
        .map(
          (stop) => LatLng(
            (stop['latitude'] as num).toDouble(),
            (stop['longitude'] as num).toDouble(),
          ),
        )
        .toList();
    final markers = <Marker>{
      for (var i = 0; i < stops.length; i++)
        Marker(
          markerId: MarkerId(stops[i]['id'].toString()),
          position: positions[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            stops[i]['source'] == 'official'
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stops[i]['name']}',
            snippet: stops[i]['source'] == 'official'
                ? 'Fuente oficial'
                : _communityLabel(stops[i]['validation_status']?.toString()),
          ),
        ),
    };
    if (widget.activeMode) {
      return PopScope(
        canPop: _allowActivePop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _minimizeActiveRoute();
        },
        child: Scaffold(body: _activeRouteBody(stops, positions, markers)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.route['title']?.toString() ?? 'Ruta')),
      body: _previewRouteBody(stops, positions, markers),
    );
  }

  Widget _routeMap(
    List<LatLng> positions,
    Set<Marker> markers, {
    required bool active,
  }) => positions.isEmpty
      ? const Center(child: Text('Sin coordenadas'))
      : GoogleMap(
          initialCameraPosition: CameraPosition(
            target: positions[_nextStopIndex.clamp(0, positions.length - 1)],
            zoom: active ? 13 : 11,
          ),
          markers: markers,
          polylines: {
            Polyline(
              polylineId: const PolylineId('preview'),
              points: _roadRoute?.points.isNotEmpty == true
                  ? _roadRoute!.points
                  : positions,
              width: active ? 7 : 5,
              color: AppColors.primary,
              patterns: _roadRoute == null
                  ? [PatternItem.dash(20), PatternItem.gap(8)]
                  : const [],
            ),
          },
          zoomControlsEnabled: false,
          myLocationEnabled: active,
          myLocationButtonEnabled: active,
          padding: active
              ? const EdgeInsets.only(top: 105, bottom: 290)
              : EdgeInsets.zero,
        );

  Widget _previewRouteBody(
    List<Map<String, dynamic>> stops,
    List<LatLng> positions,
    Set<Marker> markers,
  ) => Column(
    children: [
      SizedBox(
        height: 300,
        child: _routeMap(positions, markers, active: false),
      ),
      _routeOverview(),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: stops.length + 2,
          itemBuilder: (_, itemIndex) {
            if (itemIndex == 0) return _readinessCard(stops);
            if (itemIndex == 1) return _stopsHeader(stops.length);
            final index = itemIndex - 2;
            return _stopCard(
              stop: stops[index],
              index: index,
              isLast: index == stops.length - 1,
            );
          },
        ),
      ),
      SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE4EBE8))),
          ),
          child: _nextStopIndex >= stops.length
              ? OutlinedButton.icon(
                  onPressed: _resetProgress,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Recorrido completado · Reiniciar'),
                )
              : FilledButton.icon(
                  onPressed: _startInAppRoute,
                  icon: Icon(
                    _routeActive
                        ? Icons.navigation_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _routeActive
                        ? 'Continuar recorrido'
                        : 'Iniciar recorrido en RutaAmiga',
                  ),
                ),
        ),
      ),
    ],
  );

  Widget _readinessCard(
    List<Map<String, dynamic>> stops,
  ) => FutureBuilder<Map<String, dynamic>?>(
    future: _weatherFuture,
    builder: (context, snapshot) {
      final weather = snapshot.data;
      final readiness = const RouteReadinessService().evaluate(
        stops: stops,
        weather: weather,
        routeDurationMinutes: _roadRoute == null
            ? int.tryParse(
                    widget.route['duration_minutes']?.toString() ?? '',
                  ) ??
                  0
            : (_roadRoute!.durationSeconds / 60).round(),
        routeDistanceKm: _roadRoute == null
            ? (widget.route['distance_km'] as num?)?.toDouble() ?? 0
            : _roadRoute!.distanceMeters / 1000,
        hasRoadRoute: _roadRoute != null,
      );
      final current = Map<String, dynamic>.from(
        weather?['current'] as Map? ?? const {},
      );
      final temperature = (current['temperature_2m'] as num?)?.round();
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F8F5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD9EAE4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.backpack_outlined, color: AppColors.primary),
                SizedBox(width: 9),
                Text(
                  'Antes de salir',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _detailChip(Icons.hiking_rounded, readiness.difficulty),
                if (readiness.maxAltitudeMeters > 0)
                  _detailChip(
                    Icons.terrain_rounded,
                    '${readiness.maxAltitudeMeters} m máx.',
                  ),
                _detailChip(
                  Icons.cloud_outlined,
                  temperature == null
                      ? 'Clima no disponible'
                      : '$temperature °C ahora',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              readiness.difficultyReason,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 10,
                height: 1.35,
              ),
            ),
            if (readiness.alerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final alert in readiness.alerts.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 17,
                        color: Color(0xFFC87812),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          alert,
                          style: const TextStyle(fontSize: 11, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Lleva contigo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            for (final item in readiness.items.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _activeRouteBody(
    List<Map<String, dynamic>> stops,
    List<LatLng> positions,
    Set<Marker> markers,
  ) {
    final completed = _nextStopIndex >= stops.length;
    final stop = completed ? null : stops[_nextStopIndex];
    final progress = stops.isEmpty ? 0.0 : _nextStopIndex / stops.length;
    return Stack(
      children: [
        Positioned.fill(child: _routeMap(positions, markers, active: true)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _activeMapButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: 'Minimizar recorrido',
                    onTap: _minimizeActiveRoute,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              _PulsingRouteDot(),
                              SizedBox(width: 6),
                              Text(
                                'RECORRIDO ACTIVO',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.route['title']?.toString() ?? 'Tu ruta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.black26,
                    shape: const CircleBorder(),
                    child: PopupMenuButton<String>(
                      tooltip: 'Opciones del recorrido',
                      icon: const Icon(Icons.more_horiz_rounded),
                      onSelected: (value) {
                        if (value == 'cancel') _cancelActiveRoute();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.stop_circle_outlined),
                              SizedBox(width: 10),
                              Text('Cancelar recorrido'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFAF6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 26,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: completed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4DEDA),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.warning,
                          size: 38,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '¡Recorrido completado!',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _finishActiveRoute,
                            child: const Text('Finalizar recorrido'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4DEDA),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        _activeWeatherNotice(stops),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                width: 78,
                                height: 78,
                                child: _stopPhoto(stop!),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PRÓXIMA PARADA · ${_nextStopIndex + 1} DE ${stops.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stop['name']?.toString() ?? 'Parada',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 20,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _activeStopSubtitle(stop),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Información del lugar',
                              onPressed: () =>
                                  _showStopDetails(stop, index: _nextStopIndex),
                              icon: const Icon(Icons.info_outline_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            _activeMetric(
                              Icons.route_rounded,
                              _activeDistanceLabel(),
                            ),
                            const SizedBox(width: 8),
                            _activeMetric(
                              Icons.flag_outlined,
                              '$_nextStopIndex/${stops.length} visitadas',
                            ),
                            const Spacer(),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: progress,
                            backgroundColor: const Color(0xFFE1EAE7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              width: 54,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _showNavigationOptions,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(Icons.navigation_rounded),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: _checkingArrival
                                      ? null
                                      : _checkArrival,
                                  icon: _checkingArrival
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.location_searching_rounded,
                                        ),
                                  label: const Text(
                                    'Comprobar llegada',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeWeatherNotice(List<Map<String, dynamic>> stops) =>
      FutureBuilder<Map<String, dynamic>?>(
        future: _weatherFuture,
        builder: (_, snapshot) {
          final weather = snapshot.data;
          if (weather == null) return const SizedBox.shrink();
          final current = Map<String, dynamic>.from(
            weather['current'] as Map? ?? const {},
          );
          final readiness = const RouteReadinessService().evaluate(
            stops: stops,
            weather: weather,
            routeDurationMinutes: (_roadRoute?.durationSeconds ?? 0) ~/ 60,
            routeDistanceKm: (_roadRoute?.distanceMeters ?? 0) / 1000,
            hasRoadRoute: _roadRoute != null,
          );
          final temperature = (current['temperature_2m'] as num?)?.round();
          final message = readiness.alerts.isNotEmpty
              ? readiness.alerts.first
              : 'Condiciones sin alertas meteorológicas para esta salida.';
          return Container(
            margin: const EdgeInsets.only(top: 11),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: readiness.alerts.isEmpty
                  ? const Color(0xFFEAF5F6)
                  : const Color(0xFFFFF2DE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  readiness.alerts.isEmpty
                      ? Icons.cloud_done_outlined
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: readiness.alerts.isEmpty
                      ? const Color(0xFF247D91)
                      : const Color(0xFFC87812),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    temperature == null
                        ? message
                        : '$temperature °C · $message',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, height: 1.25),
                  ),
                ),
                const Text(
                  'Open-Meteo',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _activeMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.white,
    elevation: 5,
    shadowColor: Colors.black26,
    shape: const CircleBorder(),
    child: IconButton(tooltip: tooltip, onPressed: onTap, icon: Icon(icon)),
  );

  Widget _stopPhoto(Map<String, dynamic> stop) {
    final name = stop['name']?.toString() ?? 'Parada';
    final latitude = (stop['latitude'] as num).toDouble();
    final longitude = (stop['longitude'] as num).toDouble();
    final directPhoto = stop['photo_url']?.toString().trim() ?? '';
    if (directPhoto.isNotEmpty) {
      return Image.network(
        directPhoto,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: AppColors.primarySoft,
          child: Icon(Icons.landscape_rounded, color: AppColors.primary),
        ),
      );
    }
    return FutureBuilder<String?>(
      future: _photos.getTouristPhotoUrl(
        name: name,
        lat: latitude,
        lng: longitude,
      ),
      builder: (_, snapshot) => snapshot.data == null
          ? const ColoredBox(
              color: AppColors.primarySoft,
              child: Icon(
                Icons.landscape_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            )
          : Image.network(
              snapshot.data!,
              headers: _photos.photoHeaders,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppColors.primarySoft,
                child: Icon(Icons.landscape_rounded, color: AppColors.primary),
              ),
            ),
    );
  }

  String _activeStopSubtitle(Map<String, dynamic> stop) {
    final district = stop['district']?.toString() ?? '';
    final province = stop['province']?.toString() ?? '';
    final values = [
      district,
      province,
    ].where((value) => value.isNotEmpty).toSet().toList();
    if (values.isNotEmpty) return values.join(' · ');
    return stop['source'] == 'official'
        ? 'Atractivo oficial MINCETUR'
        : 'Lugar validado por RutaAmiga';
  }

  String _activeDistanceLabel() {
    if (_roadRoute == null) return _loadingRoute ? 'Calculando' : 'Ruta aprox.';
    return '${(_roadRoute!.distanceMeters / 1000).toStringAsFixed(1)} km ruta';
  }

  Widget _activeMetric(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.textLight, size: 15),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _routeOverview() {
    final completed = _nextStopIndex.clamp(0, _stops.length);
    final progress = _stops.isEmpty ? 0.0 : completed / _stops.length;
    String distance = 'Calculando';
    String duration = 'Ruta vial';
    final plannedMinutes =
        int.tryParse(widget.route['duration_minutes']?.toString() ?? '') ?? 0;
    final activityMinutes =
        int.tryParse(widget.route['activity_minutes']?.toString() ?? '') ?? 0;
    if (_roadRoute != null) {
      distance = '${(_roadRoute!.distanceMeters / 1000).toStringAsFixed(1)} km';
      duration = _formatMinutes((_roadRoute!.durationSeconds / 60).round());
    } else if (!_loadingRoute) {
      distance = 'Aproximada';
      duration = 'Reintentar';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4EBE8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$distance · $duration',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plannedMinutes > 0
                          ? 'Plan ${_formatMinutes(plannedMinutes)} · actividad ${_formatMinutes(activityMinutes)}'
                          : '${_stops.length} paradas · ${_travelModeLabel(_travelMode)}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loadingRoute)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$completed/${_stops.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (_routeError != null)
                IconButton(
                  onPressed: _loadRoadRoute,
                  tooltip: 'Reintentar ruta',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          if (widget.route['requires_special_planning'] == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ruta de montaña: confirma acceso, clima, aclimatación y guía local antes de salir.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 11),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE5EEEB),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stopsHeader(int total) {
    final completed = _nextStopIndex.clamp(0, total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == 1 ? 'Destino del recorrido' : 'Paradas del viaje',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '$completed de $total visitadas',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stopCard({
    required Map<String, dynamic> stop,
    required int index,
    required bool isLast,
  }) {
    final official = stop['source'] == 'official';
    final completed = index < _nextStopIndex;
    final current = index == _nextStopIndex;
    final name = stop['name']?.toString() ?? 'Parada';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.success
                        : current
                        ? AppColors.primary
                        : const Color(0xFFD9E5E2),
                    shape: BoxShape.circle,
                  ),
                  child: completed
                      ? const Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: Colors.white,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: current ? Colors.white : AppColors.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 82,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: completed
                        ? AppColors.success.withValues(alpha: .4)
                        : const Color(0xFFD9E5E2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showStopDetails(stop, index: index),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: current
                        ? AppColors.primary.withValues(alpha: .55)
                        : const Color(0xFFE4EBE8),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x090B383D),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 82,
                        height: 82,
                        child: _stopPhoto(stop),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (current)
                            const Text(
                              'Próxima parada',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                official
                                    ? Icons.verified_rounded
                                    : Icons.people_alt_rounded,
                                size: 14,
                                color: official
                                    ? AppColors.primary
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  official
                                      ? 'Oficial MINCETUR'
                                      : _communityLabel(
                                          stop['validation_status']?.toString(),
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: official
                                        ? AppColors.primary
                                        : Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((stop['category']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              _categoryLabel(stop['category']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir ubicación en Google Maps',
                      onPressed: () => _openSingleStop(stop),
                      icon: Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : Icons.arrow_outward_rounded,
                        color: completed
                            ? AppColors.success
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60} h ${minutes % 60} min' : '$minutes min';

  Future<void> _showStopDetails(
    Map<String, dynamic> stop, {
    required int index,
  }) async {
    final official = stop['source'] == 'official';
    final name = stop['name']?.toString() ?? 'Parada';
    final description = stop['description']?.toString().trim() ?? '';
    final category = _categoryLabel(stop['category']);
    final district = stop['district']?.toString().trim() ?? '';
    final province = stop['province']?.toString().trim() ?? '';
    final department = stop['department']?.toString().trim() ?? '';
    final location = [
      district,
      province,
      department,
    ].where((value) => value.isNotEmpty).toSet().join(', ');
    final altitude = (stop['altitude_m'] as num?)?.round();
    final activityMinutes = int.tryParse(
      stop['activity_minutes']?.toString() ?? '',
    );
    final activityType = stop['activity_type']?.toString().trim() ?? '';
    final difficulty = stop['difficulty']?.toString().trim() ?? '';
    final accessNote = stop['access_note']?.toString().trim() ?? '';
    final approvedAccessNote = stop['access_notes']?.toString().trim() ?? '';
    final coordinateQuality =
        stop['coordinate_quality']?.toString().trim() ?? 'reported';
    final entryType = stop['entry_type']?.toString().trim() ?? '';
    final visitHours = stop['visit_hours']?.toString().trim() ?? '';
    final visitSeason = stop['visit_season']?.toString().trim() ?? '';
    final recommendations =
        stop['visit_recommendations']?.toString().trim() ?? '';
    final activities = stop['activities']?.toString().trim() ?? '';
    final fees = <String>[
      if ((stop['adult_fee']?.toString().trim() ?? '').isNotEmpty)
        'Adulto: ${stop['adult_fee']}',
      if ((stop['child_fee']?.toString().trim() ?? '').isNotEmpty)
        'Niño: ${stop['child_fee']}',
      if ((stop['foreigner_fee']?.toString().trim() ?? '').isNotEmpty)
        'Extranjero: ${stop['foreigner_fee']}',
    ].join(' · ');
    final hasOfficialVisitInformation =
        official &&
        (entryType.isNotEmpty ||
            fees.isNotEmpty ||
            visitHours.isNotEmpty ||
            visitSeason.isNotEmpty);
    final coordinateSource = switch (coordinateQuality) {
      'verified_correction' => 'Coordenada corregida y verificada',
      'verified_access' => 'Punto de acceso revisado para navegación',
      'approximate_cluster' => 'Ubicación referencial, no apta para navegación',
      _ =>
        official
            ? 'Coordenada del registro turístico oficial'
            : 'Coordenada del aporte validado',
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .62,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5DDDA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Información de la parada',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 130,
                        child: _stopPhoto(stop),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'PARADA ${index + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 21,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      official
                          ? '✓ Atractivo oficial MINCETUR'
                          : _communityLabel(
                              stop['validation_status']?.toString(),
                            ),
                      style: TextStyle(
                        color: official ? AppColors.primary : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _detailChip(Icons.landscape_outlined, category),
                        if (location.isNotEmpty)
                          _detailChip(Icons.location_on_outlined, location),
                        if (altitude != null && altitude > 0)
                          _detailChip(
                            Icons.height_rounded,
                            '$altitude m s. n. m.',
                          ),
                        if (activityMinutes != null && activityMinutes > 0)
                          _detailChip(
                            Icons.schedule_rounded,
                            _formatMinutes(activityMinutes),
                          ),
                        if (difficulty.isNotEmpty)
                          _detailChip(
                            Icons.hiking_rounded,
                            'Dificultad ${difficulty.toLowerCase()}',
                          ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Text(
                        description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9F8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFE1E8E5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Origen de la información',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _sourceStatusRow(
                            Icons.verified_outlined,
                            'Lugar',
                            official
                                ? 'Registro turístico oficial'
                                : 'Descubrimiento de la comunidad validado',
                            confirmed: true,
                          ),
                          _sourceStatusRow(
                            Icons.location_on_outlined,
                            'Ubicación',
                            coordinateSource,
                            confirmed:
                                coordinateQuality != 'approximate_cluster',
                          ),
                          if (approvedAccessNote.isNotEmpty)
                            _sourceStatusRow(
                              Icons.route_outlined,
                              'Acceso',
                              approvedAccessNote,
                              confirmed: true,
                            ),
                          _sourceStatusRow(
                            Icons.hiking_rounded,
                            'Dificultad y duración',
                            'Estimación conservadora de RutaAmiga',
                            confirmed: false,
                          ),
                          _sourceStatusRow(
                            Icons.schedule_outlined,
                            'Horarios y tarifas',
                            hasOfficialVisitInformation
                                ? 'Datos disponibles en el registro oficial'
                                : 'No confirmados',
                            confirmed: hasOfficialVisitInformation,
                          ),
                        ],
                      ),
                    ),
                    _recentConditionCard(stop['id']?.toString() ?? ''),
                    if (entryType.isNotEmpty ||
                        fees.isNotEmpty ||
                        visitHours.isNotEmpty ||
                        visitSeason.isNotEmpty ||
                        activities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Información para tu visita',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entryType.isNotEmpty)
                        _visitDetailRow(
                          Icons.confirmation_number_outlined,
                          'Ingreso',
                          entryType,
                        ),
                      if (fees.isNotEmpty)
                        _visitDetailRow(
                          Icons.payments_outlined,
                          'Tarifas',
                          fees,
                        ),
                      if (visitHours.isNotEmpty)
                        _visitDetailRow(
                          Icons.schedule_outlined,
                          'Horario',
                          visitHours,
                        ),
                      if (visitSeason.isNotEmpty)
                        _visitDetailRow(
                          Icons.calendar_month_outlined,
                          'Mejor época',
                          visitSeason,
                        ),
                      if (activities.isNotEmpty)
                        _visitDetailRow(
                          Icons.local_activity_outlined,
                          'Actividades',
                          activities,
                        ),
                    ],
                    if (recommendations.isNotEmpty ||
                        activityType.isNotEmpty ||
                        accessNote.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F6F4),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          recommendations.isNotEmpty
                              ? recommendations
                              : accessNote.isNotEmpty
                              ? accessNote
                              : 'Actividad estimada: $activityType.',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openSingleStop(stop);
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver ubicación en Google Maps'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _visitDetailRow(
    IconData icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 17),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  static Widget _sourceStatusRow(
    IconData icon,
    String label,
    String value, {
    required bool confirmed,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: confirmed ? AppColors.primary : const Color(0xFF8A719B),
          size: 16,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textLight, fontSize: 10),
          ),
        ),
      ],
    ),
  );

  Widget _recentConditionCard(String placeId) {
    if (placeId.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>?>(
      future: _visits.conditions(placeId),
      builder: (_, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final reports =
            int.tryParse(data['verified_reports']?.toString() ?? '') ?? 0;
        final place = switch (data['place_condition']) {
          'good' => 'Bien conservado',
          'regular' => 'Estado regular',
          'poor' => 'Deteriorado',
          _ => 'Sin confirmar',
        };
        final access = switch (data['access_condition']) {
          'open' => 'Acceso abierto',
          'difficult' => 'Acceso difícil',
          'blocked' => 'Acceso bloqueado',
          _ => 'Acceso sin confirmar',
        };
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: reports > 0
                ? const Color(0xFFEAF5F1)
                : const Color(0xFFF4F5F4),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                reports > 0
                    ? Icons.people_alt_outlined
                    : Icons.help_outline_rounded,
                color: reports > 0 ? AppColors.primary : AppColors.textLight,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  reports > 0
                      ? '$place · $access\n$reports reporte${reports == 1 ? '' : 's'} con llegada GPS verificada en los últimos 30 días.'
                      : 'Aún no hay reportes recientes con llegada GPS verificada.',
                  style: const TextStyle(fontSize: 10, height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _detailChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFE1E9E6)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Future<void> _startInAppRoute() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_activeRouteKey, true);
      await ActiveRouteService.instance.start(widget.route);
      unawaited(
        PresenceService.instance.recordPosition(position, source: 'route'),
      );
      if (!mounted) return;
      setState(() => _routeActive = true);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SuggestedRouteDetailScreen(route: widget.route, activeMode: true),
        ),
      );
      if (!mounted) return;
      await _loadProgress();
      await _loadRouteSession();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa el GPS para iniciar el recorrido.'),
        ),
      );
    }
  }

  Future<void> _cancelActiveRoute() async {
    if (!widget.activeMode || _allowActivePop) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cancelar el recorrido?'),
        content: const Text(
          'La actividad dejará de aparecer en Inicio y Rutas. Las visitas ya registradas permanecerán en tu pasaporte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Seguir con la ruta'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar recorrido'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeRouteKey);
    await ActiveRouteService.instance.clear();
    if (!mounted) return;
    setState(() => _allowActivePop = true);
    _goToRoutes();
  }

  Future<void> _finishActiveRoute() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeRouteKey);
    await ActiveRouteService.instance.clear();
    if (!mounted) return;
    setState(() => _allowActivePop = true);
    _goToRoutes();
  }

  void _minimizeActiveRoute() {
    _goToRoutes();
  }

  void _goToRoutes() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) =>
            const PresenceLifecycle(child: SuggestedRoutesScreen()),
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (_) => false,
    );
  }

  Future<void> _checkArrival() async {
    if (_nextStopIndex >= _stops.length) return;
    setState(() => _checkingArrival = true);
    final stop = _stops[_nextStopIndex];
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        (stop['latitude'] as num).toDouble(),
        (stop['longitude'] as num).toDouble(),
      );
      final radius = _arrivalRadius(stop);
      if (!mounted) return;
      if (distance > radius || position.accuracy > 120) {
        await _showArrivalPending(stop, distance, radius, position.accuracy);
        return;
      }
      await _showVisitRegistration(stop, position);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos obtener una ubicación precisa. Intenta nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingArrival = false);
    }
  }

  Future<void> _showArrivalPending(
    Map<String, dynamic> stop,
    double distance,
    double radius,
    double accuracy,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_searching_rounded,
                color: AppColors.primary,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                distance > radius
                    ? 'Aún no llegas a esta parada'
                    : 'Necesitamos una señal GPS más precisa',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                distance > radius
                    ? 'Estás aproximadamente a ${distance >= 1000 ? '${(distance / 1000).toStringAsFixed(1)} km' : '${distance.round()} m'} de ${stop['name']}. La visita se habilita dentro de ${radius.round()} m.'
                    : 'La precisión actual es de ${accuracy.round()} m. Quédate unos segundos en un lugar abierto e inténtalo nuevamente.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLight, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openSingleStop(stop);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Cómo llegar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showVisitRegistration(
    Map<String, dynamic> stop,
    Position position,
  ) async {
    var rating = 5;
    String? placeCondition;
    String? accessCondition;
    File? photo;
    var saving = false;
    final commentController = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registra tu visita',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  stop['name']?.toString() ?? 'Parada',
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: saving
                      ? null
                      : () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 78,
                            maxWidth: 1800,
                          );
                          if (picked != null) {
                            setSheetState(() => photo = File(picked.path));
                          }
                        },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                      image: photo == null
                          ? null
                          : DecorationImage(
                              image: FileImage(photo!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: photo == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.primary,
                                size: 34,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tomar foto de la visita',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          )
                        : const Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.all(9),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.edit_outlined),
                              ),
                            ),
                          ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 78,
                              maxWidth: 1800,
                            );
                            if (picked != null) {
                              setSheetState(() => photo = File(picked.path));
                            }
                          },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Elegir de la galería'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Qué te pareció?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: saving
                          ? null
                          : () => setSheetState(() => rating = index + 1),
                      icon: Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF2A93B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Cómo encontraste el lugar?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  children: [
                    for (final option in const [
                      ('good', 'Bien conservado'),
                      ('regular', 'Regular'),
                      ('poor', 'Deteriorado'),
                    ])
                      ChoiceChip(
                        label: Text(option.$2),
                        selected: placeCondition == option.$1,
                        onSelected: saving
                            ? null
                            : (_) => setSheetState(
                                () => placeCondition = option.$1,
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Estado del acceso',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  children: [
                    for (final option in const [
                      ('open', 'Abierto'),
                      ('difficult', 'Difícil'),
                      ('blocked', 'Bloqueado'),
                    ])
                      ChoiceChip(
                        label: Text(option.$2),
                        selected: accessCondition == option.$1,
                        onSelected: saving
                            ? null
                            : (_) => setSheetState(
                                () => accessCondition = option.$1,
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commentController,
                  enabled: !saving,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Opinión breve',
                    hintText: '¿Qué debería saber otro viajero?',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final comment = commentController.text.trim();
                            if (photo == null || comment.length < 5) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Toma una foto y escribe una opinión breve.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            final result = await _visits.register(
                              stop: stop,
                              routeId:
                                  widget.route['id']?.toString() ??
                                  _progressKey,
                              position: position,
                              rating: rating,
                              comment: comment,
                              placeCondition: placeCondition,
                              accessCondition: accessCondition,
                              photo: photo,
                            );
                            if (!sheetContext.mounted) return;
                            Navigator.pop(
                              sheetContext,
                              result['visit_verified'] == true,
                            );
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_stories_outlined),
                    label: Text(
                      saving ? 'Guardando visita…' : 'Sellar pasaporte',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La foto podrá incorporarse a la galería después de moderación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    commentController.dispose();
    if (saved != true || !mounted) return;
    await _completeCurrentStop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Visita confirmada y guardada en tu Pasaporte RutaAmiga.',
        ),
      ),
    );
  }

  static double _arrivalRadius(Map<String, dynamic> stop) {
    final text = '${stop['name']} ${stop['category']}'.toLowerCase();
    if (text.contains('nevado') ||
        text.contains('montaña') ||
        text.contains('montana') ||
        text.contains('volcán') ||
        text.contains('volcan')) {
      return 500;
    }
    if (text.contains('cascada') ||
        text.contains('bosque') ||
        text.contains('lago') ||
        text.contains('playa') ||
        text.contains('desierto')) {
      return 300;
    }
    return 180;
  }

  Future<void> _showNavigationOptions() async {
    final stops = _stops;
    if (stops.isEmpty || _nextStopIndex >= stops.length) return;
    final next = stops[_nextStopIndex];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Cómo quieres navegar?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Siguiente: ${next['name']}',
                style: const TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 18),
              _NavigationOption(
                icon: Icons.map_rounded,
                color: const Color(0xFF4285F4),
                title: 'Google Maps',
                subtitle: 'Abrir el recorrido con todas las paradas',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openGoogleMaps();
                },
              ),
              const SizedBox(height: 10),
              _NavigationOption(
                icon: Icons.navigation_rounded,
                color: const Color(0xFF16B8E8),
                title: 'Waze',
                subtitle: 'Navegar hacia la siguiente parada',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openWaze();
                },
              ),
              const SizedBox(height: 10),
              _NavigationOption(
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.primary,
                title: 'Marcar como visitado',
                subtitle: 'Completar esta parada y continuar con la siguiente',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _completeCurrentStop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final stops = _stops.skip(_nextStopIndex).toList();
    if (stops.isEmpty) return;
    final destination = stops.last;
    final intermediate = stops
        .take(stops.length - 1)
        .map((stop) => '${stop['latitude']},${stop['longitude']}');
    final parameters = <String, String>{
      'api': '1',
      'destination': '${destination['latitude']},${destination['longitude']}',
      'travelmode': switch (_travelMode) {
        'walking' => 'walking',
        'bicycling' => 'bicycling',
        _ => 'driving',
      },
      'dir_action': 'navigate',
      if (intermediate.isNotEmpty) 'waypoints': intermediate.join('|'),
    };
    try {
      final position = await LocationService.getCurrentLocation();
      parameters['origin'] = '${position.latitude},${position.longitude}';
    } catch (_) {
      // Google Maps usará la ubicación actual si no se puede enviar el origen.
    }
    await _launchExternal(
      Uri.https('www.google.com', '/maps/dir/', parameters),
      'No se pudo abrir Google Maps.',
    );
  }

  Future<void> _openWaze() async {
    final stops = _stops;
    if (stops.isEmpty || _nextStopIndex >= stops.length) return;
    final destination = stops[_nextStopIndex];
    await _launchExternal(
      Uri.https('waze.com', '/ul', {
        'll': '${destination['latitude']},${destination['longitude']}',
        'navigate': 'yes',
        'utm_source': 'RutaAmiga',
      }),
      'No se pudo abrir Waze.',
    );
  }

  Future<void> _openSingleStop(Map<String, dynamic> stop) async {
    await _launchExternal(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${stop['latitude']},${stop['longitude']}',
      }),
      'No se pudo abrir esta parada en Google Maps.',
    );
  }

  Future<void> _launchExternal(Uri uri, String errorMessage) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  static String _communityLabel(String? status) => switch (status) {
    'validated' => 'Validado por RutaAmiga',
    'needs_review' => 'En revisión',
    _ => 'Posible atractivo',
  };

  static String _travelModeLabel(String mode) => switch (mode) {
    'walking' => 'Recorrido a pie',
    'bicycling' => 'Recorrido en bicicleta',
    _ => 'Recorrido en auto',
  };

  static String _categoryLabel(Object? value) {
    final cleaned = (value?.toString() ?? '')
        .replaceFirst(RegExp(r'^\d+\.\s*'), '')
        .toLowerCase();
    if (cleaned.isEmpty) return '';
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }
}

class _PulsingRouteDot extends StatefulWidget {
  const _PulsingRouteDot();

  @override
  State<_PulsingRouteDot> createState() => _PulsingRouteDotState();
}

class _PulsingRouteDotState extends State<_PulsingRouteDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .45, end: 1).animate(_controller),
    child: Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _RoadRoute {
  const _RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;
}

class _NavigationOption extends StatelessWidget {
  const _NavigationOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Ink(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 18),
        ],
      ),
    ),
  );
}

class _EmptyRoutes extends StatelessWidget {
  const _EmptyRoutes({
    required this.title,
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Actualizar',
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });
  final String title;
  final String message;
  final Future<void> Function() onRetry;
  final String actionLabel;
  final String? secondaryActionLabel;
  final Future<void> Function()? onSecondaryAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_outlined, size: 68, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: Text(actionLabel)),
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onSecondaryAction,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(secondaryActionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

class _RouteOptionSelection {
  const _RouteOptionSelection({
    this.durationMinutes,
    this.experience,
    this.travelMode,
    this.intent,
    this.maxDetourMinutes,
    this.changeDestination = false,
  });

  final int? durationMinutes;
  final String? experience;
  final String? travelMode;
  final String? intent;
  final int? maxDetourMinutes;
  final bool changeDestination;
}
