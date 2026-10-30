import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/widgets/main_navigation_bar.dart';
import '../../routes/screens/suggested_routes_screen.dart';

import '../models/tourist_place_model.dart';
import '../services/google_places_service.dart';
import '../services/google_routes_service.dart';
import '../services/exploration_context_service.dart';
import '../services/report_place_service.dart';
import '../services/tourist_place_service.dart';
import '../widgets/exploration_area_picker.dart';
import 'tourist_place_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final String initialLayer;
  final List<TouristPlaceModel>? routePlaces;
  final TouristPlaceModel? initialFocusPlace;

  const MapScreen({
    super.key,
    this.initialLayer = 'turisticos',
    this.routePlaces,
    this.initialFocusPlace,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _ExplorePlaceSearchDelegate extends SearchDelegate<TouristPlaceModel?> {
  _ExplorePlaceSearchDelegate(this.places, this._photos);

  final List<TouristPlaceModel> places;
  final GooglePlacesService _photos;

  @override
  String get searchFieldLabel => 'Buscar atractivo o provincia';

  List<TouristPlaceModel> get _results {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return places;
    return places.where((place) {
      return '${place.nombre} ${place.categoria} ${place.departamento} ${place.provincia} ${place.distrito}'
          .toLowerCase()
          .contains(value);
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.close_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _list();

  @override
  Widget buildSuggestions(BuildContext context) => _list();

  Widget _list() {
    final results = _results;
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No encontramos ese lugar en esta zona.',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final place = results[index];
        return ListTile(
          minVerticalPadding: 10,
          onTap: () => close(context, place),
          leading: FutureBuilder<String?>(
            future: _photos.getTouristPhotoUrl(
              name: place.nombre,
              lat: place.latitud,
              lng: place.longitud,
            ),
            builder: (context, snapshot) => Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : snapshot.data == null
                  ? const Icon(
                      Icons.landscape_outlined,
                      color: AppColors.primary,
                    )
                  : Image.network(
                      snapshot.data!,
                      headers: _photos.photoHeaders,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.landscape_outlined,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          title: Text(
            place.nombre,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            place.coordinateQuality == 'approximate_cluster'
                ? '${place.provincia}, ${place.departamento} · ubicación referencial'
                : '${place.provincia}, ${place.departamento}',
          ),
          trailing: const Icon(Icons.north_east_rounded, size: 18),
        );
      },
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  static const _touristClusterId = ClusterManagerId('tourist_places');
  static const _communityClusterId = ClusterManagerId('community_places');
  static const _serviceClusterId = ClusterManagerId('nearby_services');
  late final Set<ClusterManager> _clusterManagers;
  final ScrollController _carouselController = ScrollController();
  final DraggableScrollableController _resultsSheetController =
      DraggableScrollableController();
  final Map<String, GlobalKey> _layerKeys = {
    for (final layer in const [
      'turisticos',
      'oficiales',
      'rutaamiga',
      'restaurant',
      'lodging',
      'pharmacy',
      'gas_station',
      'atm',
    ])
      layer: GlobalKey(),
  };

  LatLng currentPosition = const LatLng(-12.0464, -77.0428);
  LatLng? _cameraTarget;
  bool _mapMoved = false;
  bool _acceptCameraMovement = false;

  bool isLoading = true;
  bool isLoadingServices = false;
  bool isLoadingRoute = false;
  bool _listMode = false;
  double? _maxDistanceKm;
  String? _categoryFilter;

  String selectedLayer = 'turisticos';
  String? routeInfo;

  List<TouristPlaceModel> nearbyPlaces = [];
  List<Map<String, dynamic>> servicePlaces = [];
  String? _selectedServiceId;

  List<Map<String, dynamic>> reportedPlaces = [];
  Map<String, dynamic>? selectedReport;

  Set<Marker> markers = {};
  Set<Marker> touristMarkers = {};
  Set<Marker> serviceMarkers = {};
  Set<Marker> reportedMarkers = {};
  Set<Polyline> routePolylines = {};

  final TouristPlaceService _placeService = TouristPlaceService();
  final GooglePlacesService _googlePlacesService = GooglePlacesService();
  final GoogleRoutesService _routesService = GoogleRoutesService();
  final ReportPlaceService _reportPlaceService = ReportPlaceService();

  @override
  void initState() {
    super.initState();
    _clusterManagers = {
      ClusterManager(
        clusterManagerId: _touristClusterId,
        onClusterTap: _focusCluster,
      ),
      ClusterManager(
        clusterManagerId: _communityClusterId,
        onClusterTap: _focusCluster,
      ),
      ClusterManager(
        clusterManagerId: _serviceClusterId,
        onClusterTap: _focusCluster,
      ),
    };
    _loadMapData();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _resultsSheetController.dispose();
    super.dispose();
  }

  void _focusCluster(Cluster cluster) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(cluster.bounds, 72),
    );
  }

  double _touristMarkerHue(TouristPlaceModel place) =>
      place.coordinateQuality == 'approximate_cluster'
      ? BitmapDescriptor.hueOrange
      : BitmapDescriptor.hueGreen;

  String _touristMarkerSnippet(TouristPlaceModel place) =>
      place.coordinateQuality == 'approximate_cluster'
      ? 'Ubicación referencial por verificar'
      : place.distrito;

  Future<void> _loadMapData() async {
    try {
      final Position position = await LocationService.getCurrentLocation();
      await ExplorationContextService.instance.restore();
      final area = ExplorationContextService.instance.area;
      currentPosition = area == null
          ? LatLng(position.latitude, position.longitude)
          : LatLng(area.latitude, area.longitude);
      _cameraTarget = currentPosition;

      if (mounted) {
        setState(() {
          isLoading = false;
          touristMarkers = {};
          markers = {...touristMarkers};
        });
      }

      unawaited(
        PresenceService.instance.recordPosition(position, source: 'map'),
      );

      final results = await Future.wait<dynamic>([
        _placeService.obtenerLugaresCercanos(
          latitud: currentPosition.latitude,
          longitud: currentPosition.longitude,
          radio: area?.radius ?? 30000,
        ),
        _reportPlaceService.obtenerReportesCercanos(
          latitud: currentPosition.latitude,
          longitud: currentPosition.longitude,
          radio: area?.radius ?? 30000,
        ),
      ]);
      final data = results[0] as List<Map<String, dynamic>>;

      nearbyPlaces = data
          .map((json) => TouristPlaceModel.fromSupabase(json))
          .toList();

      reportedPlaces = results[1] as List<Map<String, dynamic>>;

      touristMarkers = {
        ...nearbyPlaces.map(
          (place) => Marker(
            markerId: MarkerId('tourist_${place.id}'),
            clusterManagerId: _touristClusterId,
            position: LatLng(place.latitud, place.longitud),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _touristMarkerHue(place),
            ),
            infoWindow: InfoWindow(
              title: place.nombre,
              snippet: _touristMarkerSnippet(place),
            ),
            onTap: () {
              setState(() {
                selectedReport = null;
              });
              _scrollCarouselTo(nearbyPlaces.indexOf(place));
            },
          ),
        ),
      };

      final focusPlace = widget.initialFocusPlace;
      if (focusPlace != null) {
        touristMarkers.add(
          Marker(
            markerId: MarkerId('focus_${focusPlace.id}'),
            position: LatLng(focusPlace.latitud, focusPlace.longitud),
            infoWindow: InfoWindow(
              title: focusPlace.nombre,
              snippet: focusPlace.distrito,
            ),
          ),
        );
      }

      reportedMarkers = reportedPlaces.where(_isPublicReport).map((report) {
        return Marker(
          markerId: MarkerId('reported_${report['id']}'),
          clusterManagerId: _communityClusterId,
          position: LatLng(
            double.parse(report['latitud'].toString()),
            double.parse(report['longitud'].toString()),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: report['nombre'] ?? 'Lugar reportado',
            snippet: _reportedStatusLabel(
              report['estado_validacion']?.toString(),
            ),
          ),
          onTap: () {
            setState(() {
              selectedLayer = 'rutaamiga';
              selectedReport = report;
            });
          },
        );
      }).toSet();

      markers = {...touristMarkers, ...reportedMarkers};

      if (widget.routePlaces != null && widget.routePlaces!.isNotEmpty) {
        nearbyPlaces = widget.routePlaces!;

        touristMarkers = {
          ...nearbyPlaces.map(
            (place) => Marker(
              markerId: MarkerId('route_${place.id}'),
              clusterManagerId: _touristClusterId,
              position: LatLng(place.latitud, place.longitud),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _touristMarkerHue(place),
              ),
              infoWindow: InfoWindow(
                title: place.nombre,
                snippet: 'Parada del recorrido',
              ),
            ),
          ),
        };

        markers = {...touristMarkers, ...reportedMarkers};
      }

      if (mounted) setState(() {});
      if (widget.initialLayer == 'restaurant') {
        _loadNearbyServices('restaurant', 'restaurant');
      }

      if (widget.initialLayer == 'lodging') {
        _loadNearbyServices('lodging', 'lodging');
      }

      if (widget.initialLayer == 'pharmacy') {
        _loadNearbyServices('pharmacy', 'pharmacy');
      }

      if (widget.initialLayer == 'gas_station') {
        _loadNearbyServices('gas_station', 'gas_station');
      }
    } catch (e) {
      debugPrint('Error cargando lugares desde Supabase: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _searchVisibleArea() async {
    final target = _cameraTarget;
    if (target == null || widget.routePlaces != null) return;
    setState(() {
      isLoadingServices = true;
      selectedLayer = 'turisticos';
      selectedReport = null;
      routePolylines = {};
    });
    try {
      final results = await Future.wait<dynamic>([
        _placeService.obtenerLugaresCercanos(
          latitud: target.latitude,
          longitud: target.longitude,
          radio: 30000,
        ),
        _reportPlaceService.obtenerReportesCercanos(
          latitud: target.latitude,
          longitud: target.longitude,
          radio: 30000,
        ),
      ]);
      currentPosition = target;
      nearbyPlaces = (results[0] as List<Map<String, dynamic>>)
          .map(TouristPlaceModel.fromSupabase)
          .toList();
      reportedPlaces = results[1] as List<Map<String, dynamic>>;
      touristMarkers = {
        ...nearbyPlaces.map(
          (place) => Marker(
            markerId: MarkerId('tourist_${place.id}'),
            clusterManagerId: _touristClusterId,
            position: LatLng(place.latitud, place.longitud),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _touristMarkerHue(place),
            ),
            infoWindow: InfoWindow(
              title: place.nombre,
              snippet: _touristMarkerSnippet(place),
            ),
            onTap: () {
              setState(() => selectedReport = null);
              _scrollCarouselTo(nearbyPlaces.indexOf(place));
            },
          ),
        ),
      };
      reportedMarkers = reportedPlaces
          .where(_isPublicReport)
          .map(
            (report) => Marker(
              markerId: MarkerId('reported_${report['id']}'),
              clusterManagerId: _communityClusterId,
              position: LatLng(
                double.tryParse(report['latitud'].toString()) ?? 0,
                double.tryParse(report['longitud'].toString()) ?? 0,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
              infoWindow: InfoWindow(
                title: report['nombre']?.toString() ?? 'Descubrimiento',
                snippet: _reportedStatusLabel(
                  report['estado_validacion']?.toString(),
                ),
              ),
              onTap: () => setState(() => selectedReport = report),
            ),
          )
          .toSet();
      markers = {...touristMarkers, ...reportedMarkers};
    } finally {
      if (mounted) {
        setState(() {
          isLoadingServices = false;
          _mapMoved = false;
        });
      }
    }
  }

  Future<void> _loadNearbyServices(String layer, String type) async {
    try {
      setState(() {
        selectedLayer = layer;
        isLoadingServices = true;
        servicePlaces = [];
        serviceMarkers = {};
        routePolylines = {};
        routeInfo = null;
        markers = {...touristMarkers};
      });

      final places = await _googlePlacesService.getNearbyPlaces(
        lat: currentPosition.latitude,
        lng: currentPosition.longitude,
        type: type,
        radius: 3000,
      );

      servicePlaces = places;
      _selectedServiceId = null;

      serviceMarkers = places.map((place) {
        final location = place['location'];

        return Marker(
          markerId: MarkerId('service_${place['id']}'),
          clusterManagerId: _serviceClusterId,
          position: LatLng(location['latitude'], location['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: place['displayName']?['text'] ?? 'Servicio cercano',
            snippet: place['formattedAddress'] ?? '',
          ),
          onTap: () => _focusServicePlace(place, moveCamera: false),
        );
      }).toSet();

      setState(() {
        markers = {...touristMarkers, ...serviceMarkers};
        isLoadingServices = false;
      });
    } catch (e) {
      debugPrint('Error cargando servicios Google Places: $e');

      setState(() {
        isLoadingServices = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Los servicios de Google no están disponibles por ahora. Los atractivos validados siguen visibles.',
            ),
          ),
        );
      }
    }
  }

  String _reportedStatusLabel(String? status) => switch (status) {
    'validated' => 'Atractivo validado por RutaAmiga',
    'candidate' => 'Candidato de la comunidad',
    'needs_review' => 'En revisión humana',
    _ => 'Aporte de la comunidad',
  };

  bool _isPublicReport(Map<String, dynamic> report) {
    final status = (report['estado_validacion'] ?? report['status'])
        ?.toString();
    return const {
      'validated',
      'approved',
      'validated_satellite',
    }.contains(status);
  }

  void _showOnlyTouristPlaces() {
    setState(() {
      selectedLayer = 'turisticos';
      selectedReport = null;
      servicePlaces = [];
      serviceMarkers = {};
      routePolylines = {};
      routeInfo = null;
      markers = {...touristMarkers};
    });
  }

  void _showAllTouristPlaces() {
    setState(() {
      selectedLayer = 'turisticos';
      selectedReport = null;
      servicePlaces = [];
      routePolylines = {};
      routeInfo = null;
      markers = {...touristMarkers, ...reportedMarkers};
    });
  }

  void _showValidatedDiscoveries() {
    setState(() {
      selectedLayer = 'rutaamiga';
      selectedReport = null;
      servicePlaces = [];
      routePolylines = {};
      routeInfo = null;
      markers = {...reportedMarkers};
    });
  }

  Future<void> _drawRouteTo({
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      setState(() {
        isLoadingRoute = true;
        routeInfo = null;
      });

      final route = await _routesService.getRoute(
        originLat: currentPosition.latitude,
        originLng: currentPosition.longitude,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      );

      final encodedPolyline = route['polyline']['encodedPolyline'];
      final points = _decodePolyline(encodedPolyline);

      final distanceMeters = route['distanceMeters'] ?? 0;
      final durationText = route['duration'] ?? '0s';

      setState(() {
        routePolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            width: 6,
            color: AppColors.primary,
          ),
        };

        routeInfo =
            '${(distanceMeters / 1000).toStringAsFixed(1)} km • ${_formatDuration(durationText)}';

        isLoadingRoute = false;
      });
    } catch (e) {
      debugPrint('Error dibujando ruta: $e');

      setState(() {
        isLoadingRoute = false;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];

    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  String _formatDuration(String duration) {
    final seconds = int.tryParse(duration.replaceAll('s', '')) ?? 0;
    final minutes = (seconds / 60).round();

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return '${hours}h ${remainingMinutes}min';
  }

  double _distanceToTouristPlace(TouristPlaceModel place) {
    return Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          place.latitud,
          place.longitud,
        ) /
        1000;
  }

  double _distanceToService(Map<String, dynamic> place) {
    final location = place['location'];

    if (location == null) return 0;

    return Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          location['latitude'],
          location['longitude'],
        ) /
        1000;
  }

  LatLng? _serviceLatLng(Map<String, dynamic> place) {
    final location = place['location'];

    if (location == null) return null;

    return LatLng(location['latitude'], location['longitude']);
  }

  String _layerTitle() {
    switch (selectedLayer) {
      case 'restaurant':
        return 'Restaurantes cercanos';
      case 'lodging':
        return 'Hoteles cercanos';
      case 'pharmacy':
        return 'Farmacias cercanas';
      case 'gas_station':
        return 'Grifos cercanos';
      case 'atm':
        return 'Cajeros cercanos';
      default:
        return 'Lugares turísticos cerca de ti';
    }
  }

  IconData _serviceIcon() {
    switch (selectedLayer) {
      case 'restaurant':
        return Icons.restaurant;
      case 'lodging':
        return Icons.hotel;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'gas_station':
        return Icons.local_gas_station;
      case 'atm':
        return Icons.atm;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
          widget.routePlaces == null && widget.initialFocusPlace == null
          ? const MainNavigationBar(currentIndex: 1)
          : null,
      backgroundColor: AppColors.background,

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listMode
          ? _buildListMode()
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialFocusPlace == null
                        ? currentPosition
                        : LatLng(
                            widget.initialFocusPlace!.latitud,
                            widget.initialFocusPlace!.longitud,
                          ),
                    zoom: widget.initialFocusPlace == null ? 13 : 14.5,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: markers,
                  clusterManagers: _clusterManagers,
                  polylines: routePolylines,
                  onMapCreated: (controller) {
                    mapController = controller;
                    Future<void>.delayed(const Duration(milliseconds: 700), () {
                      if (mounted) _acceptCameraMovement = true;
                    });
                  },
                  onCameraMove: (position) {
                    _cameraTarget = position.target;
                    if (_acceptCameraMovement && !_mapMoved && mounted) {
                      setState(() => _mapMoved = true);
                    }
                  },
                ),

                if (_mapMoved &&
                    widget.initialFocusPlace == null &&
                    widget.routePlaces == null)
                  Positioned(
                    top: 212,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: isLoadingServices
                            ? null
                            : _searchVisibleArea,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          minimumSize: const Size(0, 44),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Buscar en esta zona'),
                      ),
                    ),
                  ),

                Positioned(
                  top: 55,
                  left: widget.initialFocusPlace == null ? 20 : 76,
                  right: 20,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: widget.initialFocusPlace == null ? 56 : 0,
                        ),
                        child: InkWell(
                          onTap: widget.routePlaces == null
                              ? () async {
                                  if (await showExplorationAreaPicker(
                                        context,
                                      ) &&
                                      mounted) {
                                    setState(() => isLoading = true);
                                    await _loadMapData();
                                    final area =
                                        ExplorationContextService.instance.area;
                                    if (area != null) {
                                      await mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          LatLng(area.latitude, area.longitude),
                                          area.scope == 'Región' ? 8.5 : 12,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.travel_explore_rounded,
                                  color: AppColors.textLight,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    widget.initialFocusPlace != null
                                        ? widget.initialFocusPlace!.nombre
                                        : widget.routePlaces != null
                                        ? '${nearbyPlaces.length} paradas del recorrido'
                                        : selectedLayer == 'turisticos'
                                        ? nearbyPlaces.isEmpty
                                              ? 'No hay lugares en esta zona'
                                              : ExplorationContextService
                                                        .instance
                                                        .area ==
                                                    null
                                              ? '${nearbyPlaces.length} lugares cerca de ti'
                                              : '${ExplorationContextService.instance.area!.name} · ${nearbyPlaces.length} lugares'
                                        : servicePlaces.isEmpty
                                        ? _layerTitle()
                                        : '${servicePlaces.length} ${_layerTitle().toLowerCase()}',
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                if (isLoadingServices || isLoadingRoute)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                if (widget.routePlaces == null &&
                                    !isLoadingServices &&
                                    !isLoadingRoute)
                                  IconButton(
                                    tooltip: 'Buscar atractivo',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _searchOfficialPlaces,
                                    icon: const Icon(
                                      Icons.search_rounded,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                if (widget.routePlaces == null &&
                                    !isLoadingServices &&
                                    !isLoadingRoute)
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textLight,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _layerBar(),
                    ],
                  ),
                ),
                if (widget.initialFocusPlace == null)
                  Positioned(
                    top: 55,
                    right: 20,
                    child: IconButton.filled(
                      tooltip: 'Ver como lista',
                      onPressed: () => setState(() => _listMode = true),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        minimumSize: const Size(50, 50),
                      ),
                      icon: const Icon(Icons.view_list_rounded),
                    ),
                  ),
                Positioned(
                  right: 20,
                  bottom: MediaQuery.sizeOf(context).height * .31,
                  child: IconButton.filled(
                    tooltip: 'Volver a mi ubicación',
                    onPressed: _recenterMap,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size(50, 50),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.my_location_rounded),
                  ),
                ),
                if (widget.initialFocusPlace != null)
                  Positioned(
                    top: 55,
                    left: 20,
                    child: IconButton.filled(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.textDark,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),

                if (routeInfo != null)
                  Positioned(
                    top: 155,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              routeInfo!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                routeInfo = null;
                                routePolylines = {};
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                _resultsSheet(),
              ],
            ),
    );
  }

  Widget _layerBar({EdgeInsets padding = EdgeInsets.zero}) {
    final scaledTextHeight = MediaQuery.textScalerOf(context).scale(13);
    final barHeight = (scaledTextHeight + 34).clamp(48.0, 64.0);
    return SizedBox(
      height: barHeight,
      child: ListView(
        padding: padding.add(const EdgeInsets.symmetric(vertical: 3)),
        scrollDirection: Axis.horizontal,
        children: [
          _layerChip(
            'Todos',
            'turisticos',
            Icons.map_outlined,
            onTap: _showAllTouristPlaces,
          ),
          _layerChip(
            'Oficiales',
            'oficiales',
            Icons.verified_outlined,
            onTap: () {
              _showOnlyTouristPlaces();
              setState(() => selectedLayer = 'oficiales');
            },
          ),
          _layerChip(
            'RutaAmiga',
            'rutaamiga',
            Icons.explore_outlined,
            onTap: _showValidatedDiscoveries,
          ),
          _layerChip(
            'Comer',
            'restaurant',
            Icons.restaurant_outlined,
            onTap: () => _loadNearbyServices('restaurant', 'restaurant'),
          ),
          _layerChip(
            'Dormir',
            'lodging',
            Icons.bed_outlined,
            onTap: () => _loadNearbyServices('lodging', 'lodging'),
          ),
          _layerChip(
            'Farmacia',
            'pharmacy',
            Icons.local_pharmacy_outlined,
            onTap: () => _loadNearbyServices('pharmacy', 'pharmacy'),
          ),
          _layerChip(
            'Combustible',
            'gas_station',
            Icons.local_gas_station_outlined,
            onTap: () => _loadNearbyServices('gas_station', 'gas_station'),
          ),
          _layerChip(
            'Cajeros',
            'atm',
            Icons.atm_outlined,
            onTap: () => _loadNearbyServices('atm', 'atm'),
          ),
        ],
      ),
    );
  }

  List<TouristPlaceModel> get _filteredOfficialPlaces {
    return nearbyPlaces.where((place) {
      final matchesDistance =
          _maxDistanceKm == null ||
          _distanceToTouristPlace(place) <= _maxDistanceKm!;
      final matchesCategory =
          _categoryFilter == null || place.categoria == _categoryFilter;
      return matchesDistance && matchesCategory;
    }).toList();
  }

  Future<void> _recenterMap() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final target = LatLng(position.latitude, position.longitude);
      currentPosition = target;
      _cameraTarget = target;
      _acceptCameraMovement = false;
      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 14),
      );
      if (mounted) {
        setState(() => _mapMoved = false);
        _acceptCameraMovement = true;
      }
      unawaited(
        PresenceService.instance.recordPosition(position, source: 'map'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos obtener tu ubicación en este momento.'),
        ),
      );
    }
  }

  Future<void> _showExploreFilters() async {
    if (selectedLayer != 'turisticos' && selectedLayer != 'oficiales') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los filtros se aplican a los atractivos turísticos.'),
        ),
      );
      return;
    }

    var distance = _maxDistanceKm;
    var category = _categoryFilter;
    final categories = nearbyPlaces
        .map((place) => place.categoria.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(8)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5D0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '¿Qué quieres descubrir?',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Distancia desde tu punto de exploración',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final option in <double?>[null, 5, 15, 30])
                          ChoiceChip(
                            label: Text(
                              option == null
                                  ? 'Sin límite'
                                  : '${option.toInt()} km',
                            ),
                            selected: distance == option,
                            onSelected: (_) =>
                                setSheetState(() => distance = option),
                          ),
                      ],
                    ),
                    if (categories.length > 1) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Tipo de lugar',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 130),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Todos'),
                                selected: category == null,
                                onSelected: (_) =>
                                    setSheetState(() => category = null),
                              ),
                              for (final option in categories)
                                ChoiceChip(
                                  label: Text(option),
                                  selected: category == option,
                                  onSelected: (_) =>
                                      setSheetState(() => category = option),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _maxDistanceKm = distance;
                            _categoryFilter = category;
                            _applyTouristFiltersToMap();
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Ver resultados'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyTouristFiltersToMap() {
    final visiblePlaces = _filteredOfficialPlaces;
    touristMarkers = visiblePlaces
        .map(
          (place) => Marker(
            markerId: MarkerId('tourist_${place.id}'),
            clusterManagerId: _touristClusterId,
            position: LatLng(place.latitud, place.longitud),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _touristMarkerHue(place),
            ),
            infoWindow: InfoWindow(
              title: place.nombre,
              snippet: place.distrito,
            ),
            onTap: () {
              setState(() => selectedReport = null);
              _scrollCarouselTo(visiblePlaces.indexOf(place));
            },
          ),
        )
        .toSet();
    markers = selectedLayer == 'oficiales'
        ? {...touristMarkers}
        : {...touristMarkers, ...reportedMarkers};
  }

  int get _resultCount {
    if (selectedLayer == 'rutaamiga') {
      return reportedPlaces.where(_isPublicReport).length;
    }
    if (selectedLayer == 'turisticos' || selectedLayer == 'oficiales') {
      return _filteredOfficialPlaces.length;
    }
    return servicePlaces.length;
  }

  String get _resultsTitle => switch (selectedLayer) {
    'rutaamiga' => 'Descubrimientos validados',
    'oficiales' => 'Atractivos oficiales',
    'restaurant' => 'Dónde comer',
    'lodging' => 'Dónde dormir',
    'pharmacy' => 'Farmacias cercanas',
    'gas_station' => 'Combustible cercano',
    'atm' => 'Cajeros cercanos',
    _ => 'Explora esta zona',
  };

  Widget _resultsSheet() => DraggableScrollableSheet(
    controller: _resultsSheetController,
    initialChildSize: .29,
    minChildSize: .105,
    maxChildSize: .76,
    snap: true,
    snapSizes: const [.105, .29, .76],
    builder: (context, scrollController) => Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 9),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5D0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resultsTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$_resultCount resultados · desliza para ver todos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Filtrar resultados',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  onPressed: _showExploreFilters,
                  icon: Badge(
                    isLabelVisible:
                        _maxDistanceKm != null || _categoryFilter != null,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
                IconButton(
                  tooltip: 'Crear una ruta',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuggestedRoutesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.route_outlined),
                ),
                IconButton(
                  tooltip: 'Ver lista completa',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  onPressed: () => setState(() => _listMode = true),
                  icon: const Icon(Icons.view_list_rounded),
                ),
              ],
            ),
          ),
          SizedBox(height: 148, child: _resultCarousel()),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Todos los resultados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          ..._verticalResultTiles(),
          const SizedBox(height: 30),
        ],
      ),
    ),
  );

  Widget _resultCarousel() {
    if (selectedReport != null) {
      return _buildReportedPlaceCard(selectedReport!);
    }
    if (selectedLayer == 'turisticos' || selectedLayer == 'oficiales') {
      return _buildTouristCards();
    }
    if (selectedLayer == 'rutaamiga') return _buildDiscoveryCards();
    return _buildServiceCards();
  }

  List<Widget> _verticalResultTiles() {
    if (isLoadingServices) {
      return const [
        Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (selectedLayer == 'turisticos' || selectedLayer == 'oficiales') {
      return _filteredOfficialPlaces.take(20).map(_officialResultTile).toList();
    }
    if (selectedLayer == 'rutaamiga') {
      return reportedPlaces
          .where(_isPublicReport)
          .take(20)
          .map(_communityResultTile)
          .toList();
    }
    return servicePlaces.take(20).map(_serviceResultTile).toList();
  }

  Widget _buildListMode() => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explorar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${ExplorationContextService.instance.area?.name ?? 'Cerca de ti'} · $_resultCount resultados',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Buscar',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: _searchOfficialPlaces,
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: 'Filtrar',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: _showExploreFilters,
                icon: Badge(
                  isLabelVisible:
                      _maxDistanceKm != null || _categoryFilter != null,
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
              IconButton(
                tooltip: 'Crear ruta',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuggestedRoutesScreen(),
                  ),
                ),
                icon: const Icon(Icons.route_outlined),
              ),
              IconButton.filled(
                tooltip: 'Ver mapa',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: () => setState(() => _listMode = false),
                icon: const Icon(Icons.map_outlined),
              ),
            ],
          ),
        ),
        _layerBar(padding: const EdgeInsets.symmetric(horizontal: 20)),
        const SizedBox(height: 10),
        Expanded(
          child: isLoadingServices
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                  children: _verticalResultTiles(),
                ),
        ),
      ],
    ),
  );

  void _scrollCarouselTo(int index, {double itemExtent = 324}) {
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_carouselController.hasClients) return;
      final target = (index * itemExtent).clamp(
        0.0,
        _carouselController.position.maxScrollExtent,
      );
      _carouselController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _focusServicePlace(
    Map<String, dynamic> place, {
    bool moveCamera = true,
  }) {
    final id = place['id']?.toString();
    final index = servicePlaces.indexWhere(
      (item) => item['id']?.toString() == id,
    );
    final location = _serviceLatLng(place);
    setState(() {
      _listMode = false;
      _selectedServiceId = id;
    });
    if (moveCamera && location != null) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
    }
    _scrollCarouselTo(index, itemExtent: 334);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_resultsSheetController.isAttached) return;
      _resultsSheetController.animateTo(
        .34,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _searchOfficialPlaces() async {
    final place = await showSearch<TouristPlaceModel?>(
      context: context,
      delegate: _ExplorePlaceSearchDelegate(
        _filteredOfficialPlaces,
        _googlePlacesService,
      ),
    );
    if (place != null && mounted) _focusOfficialPlace(place);
  }

  void _focusOfficialPlace(TouristPlaceModel place) {
    final index = _filteredOfficialPlaces.indexWhere(
      (item) => item.id == place.id,
    );
    setState(() {
      _listMode = false;
      selectedReport = null;
      if (selectedLayer != 'turisticos' && selectedLayer != 'oficiales') {
        selectedLayer = 'oficiales';
        markers = {...touristMarkers};
      }
    });
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(place.latitud, place.longitud), 15),
    );
    _scrollCarouselTo(index);
  }

  Widget _officialResultTile(TouristPlaceModel place) {
    final distance = _distanceToTouristPlace(place);
    return InkWell(
      onTap: () => _focusOfficialPlace(place),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            FutureBuilder<String?>(
              future: _googlePlacesService.getTouristPhotoUrl(
                name: place.nombre,
                lat: place.latitud,
                lng: place.longitud,
              ),
              builder: (_, snapshot) => Container(
                width: 62,
                height: 62,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: snapshot.data == null
                    ? const Icon(Icons.landscape, color: AppColors.primary)
                    : Image.network(
                        snapshot.data!,
                        headers: _googlePlacesService.photoHeaders,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.landscape,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OFICIAL MINCETUR',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 8,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.provincia} · ${distance.toStringAsFixed(1)} km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ver detalle',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TouristPlaceDetailScreen(
                    place: place,
                    distance: distance,
                  ),
                ),
              ),
              icon: const Icon(Icons.arrow_outward_rounded, size: 19),
            ),
          ],
        ),
      ),
    );
  }

  Widget _communityResultTile(Map<String, dynamic> report) {
    final photo = report['foto_url']?.toString();
    final lat = double.tryParse(report['latitud'].toString()) ?? 0;
    final lng = double.tryParse(report['longitud'].toString()) ?? 0;
    return InkWell(
      onTap: () {
        setState(() {
          _listMode = false;
          selectedReport = report;
        });
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E8F6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: photo == null || photo.isEmpty
                  ? const Icon(Icons.explore, color: Color(0xFF7655A6))
                  : Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.explore, color: Color(0xFF7655A6)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VALIDADO POR RUTAAMIGA',
                    style: TextStyle(
                      color: Color(0xFF7655A6),
                      fontSize: 8,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report['nombre']?.toString() ?? 'Descubrimiento',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report['categoria_ia']?.toString() ?? 'Lugar natural',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.location_on_outlined, color: Color(0xFF7655A6)),
          ],
        ),
      ),
    );
  }

  Widget _serviceResultTile(Map<String, dynamic> place) {
    final location = _serviceLatLng(place);
    final name = place['displayName']?['text']?.toString() ?? 'Servicio';
    final photoUrl = _googlePlacesService.getPhotoUrl(place);
    return InkWell(
      onTap: location == null ? null : () => _focusServicePlace(place),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1F5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: photoUrl == null
                  ? Icon(_serviceIcon(), color: AppColors.primary)
                  : Image.network(
                      photoUrl,
                      headers: _googlePlacesService.photoHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(_serviceIcon(), color: AppColors.primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place['formattedAddress']?.toString() ?? _layerTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_distanceToService(place).toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
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

  Widget _buildTouristCards() {
    final places = _filteredOfficialPlaces;
    if (places.isEmpty) {
      return _emptyCard(
        'No encontramos atractivos con estos filtros. Prueba ampliando la distancia.',
      );
    }

    return ListView.separated(
      controller: _carouselController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final place = places[index];

        final photoFuture = _googlePlacesService.getTouristPhotoUrl(
          name: place.nombre,
          lat: place.latitud,
          lng: place.longitud,
        );

        return _touristPlaceCard(place, photoFuture);
      },
    );
  }

  Widget _buildDiscoveryCards() {
    final discoveries = reportedPlaces.where(_isPublicReport).toList();
    if (discoveries.isEmpty) {
      return _emptyCard(
        'Todavía no hay descubrimientos validados en esta zona.',
      );
    }
    return ListView.separated(
      controller: _carouselController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: discoveries.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, index) {
        final report = discoveries[index];
        return InkWell(
          onTap: () {
            final lat = double.tryParse(report['latitud'].toString()) ?? 0;
            final lng = double.tryParse(report['longitud'].toString()) ?? 0;
            setState(() => selectedReport = report);
            mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: 286,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EAF8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.explore, color: Color(0xFF7655A6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['nombre']?.toString() ?? 'Descubrimiento',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Validado por RutaAmiga',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportedPlaceCard(Map<String, dynamic> report) {
    final fotoUrl = report['foto_url']?.toString();
    final nombre = report['nombre']?.toString() ?? 'Lugar reportado';
    final descripcion =
        report['descripcion']?.toString() ?? 'Sin descripción registrada.';
    final categoria = report['categoria_ia']?.toString() ?? 'Sin categoría';

    final lat = double.tryParse(report['latitud'].toString()) ?? 0;
    final lng = double.tryParse(report['longitud'].toString()) ?? 0;

    final distance =
        Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          lat,
          lng,
        ) /
        1000;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      children: [
        Container(
          width: 340,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: fotoUrl == null || fotoUrl.isEmpty
                    ? const Icon(
                        Icons.image_outlined,
                        color: Colors.purple,
                        size: 38,
                      )
                    : Image.network(
                        fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.image_outlined,
                            color: Colors.purple,
                            size: 38,
                          );
                        },
                      ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF7655A6),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Validado por RutaAmiga',
                          style: TextStyle(
                            color: Color(0xFF7655A6),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      categoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.near_me,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedReport = null;
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
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

  Widget _buildServiceCards() {
    if (isLoadingServices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (servicePlaces.isEmpty) {
      return _emptyCard(
        'No se encontraron servicios cercanos para esta categoría.',
      );
    }

    return ListView.separated(
      controller: _carouselController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: servicePlaces.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final place = servicePlaces[index];
        return _servicePlaceCard(place);
      },
    );
  }

  Widget _layerChip(
    String label,
    String layer,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedLayer == layer;

    return Padding(
      key: _layerKeys[layer],
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          onTap();
          _revealLayerChip(layer);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : AppColors.primary,
              ),

              const SizedBox(width: 6),

              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _revealLayerChip(String layer) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chipContext = _layerKeys[layer]?.currentContext;
      if (chipContext == null) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: .5,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _emptyCard(String message) {
    return Center(
      child: Container(
        width: 310,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textLight, height: 1.4),
        ),
      ),
    );
  }

  Widget _touristPlaceCard(
    TouristPlaceModel place,
    Future<String?> photoFuture,
  ) {
    final distance = _distanceToTouristPlace(place);

    return GestureDetector(
      onTap: () {
        _drawRouteTo(
          destinationLat: place.latitud,
          destinationLng: place.longitud,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TouristPlaceDetailScreen(place: place, distance: distance),
          ),
        );
      },
      child: Container(
        width: 310,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            FutureBuilder<String?>(
              future: photoFuture,
              builder: (context, snapshot) {
                final photoUrl = snapshot.data;

                return Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.place,
                          color: AppColors.primary,
                          size: 36,
                        )
                      : Image.network(
                          photoUrl,
                          headers: _googlePlacesService.photoHeaders,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.place,
                              color: AppColors.primary,
                              size: 36,
                            );
                          },
                        ),
                );
              },
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    place.categoria,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${place.distrito}, ${place.provincia}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      const Icon(
                        Icons.near_me,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicePlaceCard(Map<String, dynamic> place) {
    final name = place['displayName']?['text'] ?? 'Servicio cercano';
    final address = place['formattedAddress'] ?? 'Dirección no disponible';
    final rating = place['rating'];
    final distance = _distanceToService(place);
    final photoUrl = _googlePlacesService.getPhotoUrl(place);

    final isSelected = place['id']?.toString() == _selectedServiceId;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedServiceId = place['id']?.toString());
        final latLng = _serviceLatLng(place);

        if (latLng != null) {
          mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));

          _drawRouteTo(
            destinationLat: latLng.latitude,
            destinationLng: latLng.longitude,
          );
        }
      },
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl == null
                  ? Icon(_serviceIcon(), color: AppColors.primary, size: 34)
                  : Image.network(
                      photoUrl,
                      headers: _googlePlacesService.photoHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          _serviceIcon(),
                          color: AppColors.primary,
                          size: 34,
                        );
                      },
                    ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 14),
                      ],

                      const Icon(
                        Icons.near_me,
                        size: 16,
                        color: AppColors.primary,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
