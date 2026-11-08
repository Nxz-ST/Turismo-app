import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../places/models/tourist_place_model.dart';
import '../../places/screens/community_place_detail_screen.dart';
import '../../places/screens/tourist_place_detail_screen.dart';
import '../../routes/screens/custom_route_builder_screen.dart';
import '../../routes/screens/suggested_routes_screen.dart';
import '../../places/services/weather_service.dart';
import '../../places/services/google_places_service.dart';
import '../../routes/services/route_readiness_service.dart';
import '../services/trip_progress_service.dart';
import '../services/travel_library_service.dart';
import '../services/trip_schedule_service.dart';

class MyTripScreen extends StatefulWidget {
  const MyTripScreen({super.key});

  @override
  State<MyTripScreen> createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  final _library = TravelLibraryService.instance;
  List<TouristPlaceModel> _places = [];
  Set<String> _completed = {};
  List<String> _alerts = const [];
  bool _loading = true;
  bool _preparingOffline = false;
  DateTime? _departure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final places = await _library.trip();
    final completed = await TripProgressService().completed();
    final departure = await TripScheduleService().load();
    if (!mounted) return;
    setState(() {
      _places = places;
      _completed = completed;
      _departure = departure;
      _loading = false;
    });
    await _loadAlerts(places);
  }

  Future<void> _loadAlerts(List<TouristPlaceModel> places) async {
    var alerts = <String>[];
    if (places.isNotEmpty) {
      try {
        final first = places.first;
        final weather = await WeatherService().forecast(
          latitude: first.latitud,
          longitude: first.longitud,
        );
        alerts = const RouteReadinessService()
            .evaluate(
              stops: [_stopFromPlace(first)],
              weather: weather,
              routeDurationMinutes: places.length * 90,
            )
            .alerts;
      } catch (_) {
        alerts = [
          'Consulta el clima y las condiciones de acceso antes de salir.',
        ];
      }
    }
    if (!mounted) return;
    setState(() => _alerts = alerts);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi viaje'),
      actions: [
        IconButton(
          tooltip: 'Mis rutas guardadas',
          onPressed: _openSavedRoutes,
          icon: const Icon(Icons.bookmarks_outlined),
        ),
        if (_places.length > 1)
          IconButton(
            tooltip: 'Optimizar recorrido',
            onPressed: _optimize,
            icon: const Icon(Icons.auto_fix_high_rounded),
          ),
        if (_places.isNotEmpty)
          IconButton(
            tooltip: 'Compartir viaje',
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded),
          ),
      ],
    ),
    body: _loading
        ? const AppStateView.loading(
            message: 'Organizando tus paradas y condiciones del viaje…',
          )
        : _places.isEmpty
        ? _EmptyTrip(onCreate: _openBuilder)
        : Column(
            children: [
              _scheduleCard(),
              _progressHeader(),
              if (_alerts.isNotEmpty) _alertCard(),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.drag_indicator, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Arrastra las barras de cada parada para cambiar el orden.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  itemCount: _places.length,
                  onReorder: (oldIndex, newIndex) async {
                    await _library.reorderTrip(oldIndex, newIndex);
                    await _load();
                  },
                  itemBuilder: (_, index) {
                    final place = _places[index];
                    final completed = _completed.contains(place.libraryKey);
                    return InkWell(
                      key: ValueKey(place.libraryKey),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openPlace(place),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE4EBE8)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: completed
                                  ? AppColors.success
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              child: completed
                                  ? const Icon(Icons.check_rounded)
                                  : Text('${index + 1}'),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${place.distrito}, ${place.provincia}',
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: completed
                                  ? 'Marcar como pendiente'
                                  : 'Marcar como visitado',
                              onPressed: () async {
                                await TripProgressService().setCompleted(
                                  place.libraryKey,
                                  !completed,
                                );
                                await _load();
                              },
                              icon: Icon(
                                completed
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: completed
                                    ? AppColors.success
                                    : AppColors.textLight,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await _library.removeFromTrip(place);
                                await _load();
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                                child: Icon(Icons.drag_handle_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openRoutePreview,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Vista previa'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _prepareNavigation,
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('Navegar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );

  Widget _progressHeader() {
    final done = _places
        .where((place) => _completed.contains(place.libraryKey))
        .length;
    final progress = _places.isEmpty ? 0.0 : done / _places.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E9E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: AppColors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  done == _places.length
                      ? '¡Viaje completado!'
                      : '$done de ${_places.length} lugares visitados',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text('${(progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, minHeight: 7),
        ],
      ),
    );
  }

  Widget _scheduleCard() => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0E735C), Color(0xFF164E43)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white24,
          foregroundColor: Colors.white,
          child: Icon(Icons.calendar_month_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _departure == null
                    ? '¿Cuándo empieza tu viaje?'
                    : _formatDeparture(_departure!),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _departure == null
                    ? 'Programa la salida para tener la ruta lista.'
                    : 'Ruta guardada y recordatorio visible en tu planificación.',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Preparar sin conexión',
          onPressed: _preparingOffline ? null : _prepareOffline,
          color: Colors.white,
          icon: _preparingOffline
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_for_offline_outlined),
        ),
        TextButton(
          onPressed: _pickDeparture,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(_departure == null ? 'Programar' : 'Cambiar'),
        ),
      ],
    ),
  );

  String _formatDeparture(DateTime value) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final minute = value.minute.toString().padLeft(2, '0');
    return 'Salida: ${value.day} ${months[value.month - 1]} · ${value.hour}:$minute';
  }

  Future<void> _pickDeparture() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _departure?.isAfter(now) == true ? _departure! : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      helpText: 'Fecha de salida',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _departure ?? now.add(const Duration(hours: 1)),
      ),
      helpText: 'Hora de salida',
    );
    if (time == null) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await TripScheduleService().save(value);
    await LocalNotificationService.instance.scheduleTripReminder(
      value,
      _places.first.nombre,
    );
    if (!mounted) return;
    setState(() => _departure = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida programada: ${_formatDeparture(value)}.')),
    );
  }

  Future<void> _prepareOffline() async {
    setState(() => _preparingOffline = true);
    final photos = GooglePlacesService();
    var cached = 0;
    for (final place in _places) {
      var url = place.primaryPhotoUrl;
      Map<String, String>? headers;
      if (url.isEmpty && place.source != 'community') {
        url =
            await photos.getTouristPhotoUrl(
              name: place.nombre,
              lat: place.latitud,
              lng: place.longitud,
            ) ??
            '';
        headers = photos.photoHeaders;
      }
      if (url.isEmpty || !mounted) continue;
      try {
        await precacheImage(
          CachedNetworkImageProvider(url, headers: headers),
          context,
        );
        cached++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _preparingOffline = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Viaje preparado: ${_places.length} fichas y $cached fotografías disponibles.',
        ),
      ),
    );
  }

  Widget _alertCard() => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5E7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF1D4A3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.notifications_active_outlined,
          color: Color(0xFF9A6710),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _alerts.take(2).join('\n'),
            style: const TextStyle(fontSize: 11, height: 1.4),
          ),
        ),
      ],
    ),
  );

  static Map<String, dynamic> _stopFromPlace(TouristPlaceModel place) => {
    'name': place.nombre,
    'category': place.categoria,
    'activities': place.actividades,
    'altitude_m': place.altitud,
    'coordinate_quality': place.coordinateQuality,
    'source': place.source,
    'difficulty': 'moderada',
  };

  Future<void> _openRoutePreview() => _openRouteDetail();

  Future<void> _openPlace(TouristPlaceModel place) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => place.source == 'community'
            ? CommunityPlaceDetailScreen(initialPlace: place.toCommunityJson())
            : TouristPlaceDetailScreen(place: place, distance: 0),
      ),
    );
  }

  Future<void> _prepareNavigation() => _openRouteDetail();

  Future<void> _openSavedRoutes() async {
    var routes = await _library.savedRoutes();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .68,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mis rutas guardadas',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (_places.length >= 2)
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final name = await _askRouteName(sheetContext);
                            if (name == null || name.trim().isEmpty) return;
                            await _library.saveCurrentTrip(name);
                            routes = await _library.savedRoutes();
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Guardar actual'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: routes.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Todavía no guardaste rutas. Organiza al menos dos paradas y guarda el recorrido.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textLight),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: routes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (_, index) {
                            final route = routes[index];
                            final places = route['places'] as List? ?? const [];
                            return ListTile(
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: const BorderSide(
                                  color: Color(0xFFE1E8E5),
                                ),
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primarySoft,
                                child: Icon(
                                  Icons.route_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                route['name']?.toString() ?? 'Ruta guardada',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text('${places.length} paradas'),
                              onTap: () async {
                                await _library.loadSavedRoute(
                                  route['id'].toString(),
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                await _load();
                              },
                              trailing: IconButton(
                                tooltip: 'Eliminar ruta guardada',
                                onPressed: () async {
                                  await _library.deleteSavedRoute(
                                    route['id'].toString(),
                                  );
                                  routes = await _library.savedRoutes();
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _askRouteName(BuildContext dialogContext) async {
    final controller = TextEditingController(
      text: 'Ruta ${DateTime.now().day}/${DateTime.now().month}',
    );
    final result = await showDialog<String>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Guardar esta ruta'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nombre de la ruta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _openRouteDetail() async {
    if (_places.length < 2) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestedRouteDetailScreen(route: _customRoute),
      ),
    );
  }

  Map<String, dynamic> get _customRoute {
    final province = _places
        .map((place) => place.provincia.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => 'tu destino');
    final activityMinutes = _places.length * 90;
    return {
      'id': 'custom-${_places.map((place) => place.id).join('-')}',
      'title': 'Mi ruta por ${_titleCase(province)}',
      'subtitle': 'Recorrido personalizado con ${_places.length} paradas',
      'kind': 'custom',
      'distance_km': 0,
      'duration_minutes': activityMinutes,
      'travel_minutes': 0,
      'activity_minutes': activityMinutes,
      'estimate_kind': 'custom_route',
      'requires_special_planning': false,
      'navigation_mode': 'preview',
      'travel_mode': 'driving',
      'stops': [
        for (final place in _places)
          {
            'id': place.libraryKey,
            'name': place.nombre,
            'description': place.descripcion,
            'latitude': place.navigationLatitud,
            'longitude': place.navigationLongitud,
            'attraction_latitude': place.latitud,
            'attraction_longitude': place.longitud,
            'navigation_coordinate_role': place.hasVerifiedAccess
                ? 'access_point'
                : 'attraction',
            'access_notes': place.accessNotes,
            'category': place.categoria,
            'source': place.source,
            'validation_status': place.source == 'community'
                ? 'validated'
                : 'official',
            'district': place.distrito,
            'province': place.provincia,
            'department': place.departamento,
            'altitude_m': place.altitud,
            'entry_type': place.tipoIngreso,
            'adult_fee': place.tarifaAdulto,
            'child_fee': place.tarifaNino,
            'foreigner_fee': place.tarifaExtranjero,
            'visit_season': place.epocaVisita,
            'visit_hours': place.horarioVisita,
            'visit_recommendations': place.recomendacionesVisita,
            'activities': place.actividades,
            'coordinate_quality': place.coordinateQuality,
            'activity_minutes': 90,
            'activity_type': 'visita personalizada',
            'difficulty': 'moderada',
          },
      ],
    };
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Future<void> _openBuilder() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CustomRouteBuilderScreen()),
    );
    if (saved == true) await _load();
  }

  Future<void> _optimize() async {
    var latitude = _places.first.navigationLatitud;
    var longitude = _places.first.navigationLongitud;
    try {
      final position = await LocationService.getCurrentLocation();
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (_) {}
    final pending = [..._places];
    final optimized = <TouristPlaceModel>[];
    while (pending.isNotEmpty) {
      pending.sort(
        (a, b) =>
            Geolocator.distanceBetween(
              latitude,
              longitude,
              a.navigationLatitud,
              a.navigationLongitud,
            ).compareTo(
              Geolocator.distanceBetween(
                latitude,
                longitude,
                b.navigationLatitud,
                b.navigationLongitud,
              ),
            ),
      );
      final next = pending.removeAt(0);
      optimized.add(next);
      latitude = next.navigationLatitud;
      longitude = next.navigationLongitud;
    }
    await _library.replaceTrip(optimized);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orden optimizado por cercanía.')),
    );
  }

  Future<void> _share() async {
    final text = StringBuffer('Mi viaje en RutaAmiga:\n');
    for (var index = 0; index < _places.length; index++) {
      final place = _places[index];
      text.writeln('${index + 1}. ${place.nombre} — ${place.provincia}');
    }
    await Share.share(text.toString(), subject: 'Mi viaje en RutaAmiga');
  }
}

class _EmptyTrip extends StatelessWidget {
  const _EmptyTrip({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.luggage_outlined,
            size: 68,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu viaje está vacío',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Elige dos o más lugares y crea un recorrido a tu manera.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.alt_route_rounded),
            label: const Text('Crear mi ruta'),
          ),
        ],
      ),
    ),
  );
}
