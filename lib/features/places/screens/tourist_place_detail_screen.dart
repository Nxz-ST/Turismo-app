import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../profile/services/travel_library_service.dart';
import '../models/tourist_place_model.dart';
import '../services/google_places_service.dart';
import '../services/weather_service.dart';
import '../widgets/place_trust_passport_card.dart';
import 'map_screen.dart';

class TouristPlaceDetailScreen extends StatelessWidget {
  const TouristPlaceDetailScreen({
    super.key,
    required this.place,
    required this.distance,
  });

  final TouristPlaceModel place;
  final double distance;

  static final GooglePlacesService _photos = GooglePlacesService();

  bool _hasValue(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != 'null' &&
        normalized != 'no disponible';
  }

  String get _description => _hasValue(place.descripcion)
      ? place.descripcion.trim()
      : 'Aún no contamos con una descripción completa de este lugar.';

  String get _category {
    final raw = place.categoria.trim();
    final separator = raw.indexOf('.');
    if (separator >= 0 && separator < raw.length - 1) {
      return raw.substring(separator + 1).trim();
    }
    return raw.isEmpty ? 'Lugar turístico' : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            title: Text(
              place.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [_FavoriteButton(place: place)],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _photoHero(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            sliver: SliverList.list(
              children: [
                const _OfficialBadge(),
                const SizedBox(height: 12),
                Text(
                  place.nombre,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${place.distrito}, ${place.provincia}, ${place.departamento}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _primaryAction(context),
                const SizedBox(height: 24),
                _facts(),
                const SizedBox(height: 14),
                PlaceTrustPassportCard(
                  source: 'official',
                  placeId: place.id.toString(),
                ),
                const SizedBox(height: 14),
                _WeatherSafetyCard(place: place),
                const SizedBox(height: 30),
                const _SectionTitle('Sobre este lugar'),
                const SizedBox(height: 12),
                Text(
                  _description,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 30),
                const _SectionTitle('Cerca de aquí'),
                const SizedBox(height: 12),
                _NearbyServicesSection(place: place),
                if (_hasVisitInformation) ...[
                  const SizedBox(height: 30),
                  const _SectionTitle('Información para tu visita'),
                  const SizedBox(height: 12),
                  _visitInformation(),
                ],
                if (_hasPrices) ...[
                  const SizedBox(height: 30),
                  const _SectionTitle('Tarifas referenciales'),
                  const SizedBox(height: 12),
                  _prices(),
                ],
                const SizedBox(height: 22),
                _ReviewsSection(place: place),
                const SizedBox(height: 22),
                _technicalLocation(),
                const SizedBox(height: 16),
                const Text(
                  'Información turística: MINCETUR. Fotografías de Google Places y aportes validados de la comunidad, según disponibilidad.',
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
  }

  Widget _photoHero() =>
      _ProgressivePlaceGallery(place: place, photos: _photos);

  Widget _primaryAction(BuildContext context) => Row(
    children: [
      Expanded(
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(initialFocusPlace: place),
            ),
          ),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Ver mapa'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: _AddToTripButton(place: place)),
    ],
  );

  Widget _facts() => Row(
    children: [
      Expanded(
        child: _FactCard(
          icon: Icons.landscape_outlined,
          label: 'Categoría',
          value: _category,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _FactCard(
          icon: Icons.near_me_outlined,
          label: 'Distancia',
          value: distance > .05
              ? '${distance.toStringAsFixed(1)} km'
              : 'En mapa',
        ),
      ),
      if (place.altitud > 0) ...[
        const SizedBox(width: 10),
        Expanded(
          child: _FactCard(
            icon: Icons.height_rounded,
            label: 'Altitud',
            value: '${place.altitud.toStringAsFixed(0)} m',
          ),
        ),
      ],
    ],
  );

  bool get _hasVisitInformation =>
      _hasValue(place.tipoIngreso) ||
      _hasValue(place.horarioVisita) ||
      _hasValue(place.epocaVisita) ||
      _hasValue(place.actividades) ||
      _hasValue(place.recomendacionesVisita);

  Widget _visitInformation() {
    final items = <(IconData, String, String)>[
      (Icons.confirmation_number_outlined, 'Ingreso', place.tipoIngreso),
      (Icons.schedule_rounded, 'Horario', place.horarioVisita),
      (Icons.calendar_month_outlined, 'Mejor época', place.epocaVisita),
      (Icons.local_activity_outlined, 'Actividades', place.actividades),
      (
        Icons.tips_and_updates_outlined,
        'Recomendaciones',
        place.recomendacionesVisita,
      ),
    ].where((item) => _hasValue(item.$3)).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _VisitRow(
              icon: items[index].$1,
              title: items[index].$2,
              value: items[index].$3,
            ),
            if (index < items.length - 1) const Divider(height: 1, indent: 54),
          ],
        ],
      ),
    );
  }

  bool get _hasPrices =>
      _hasValue(place.tarifaAdulto) ||
      _hasValue(place.tarifaNino) ||
      _hasValue(place.tarifaExtranjero);

  Widget _prices() => Row(
    children: [
      if (_hasValue(place.tarifaAdulto))
        Expanded(
          child: _PriceCard(label: 'Adulto', value: place.tarifaAdulto),
        ),
      if (_hasValue(place.tarifaNino)) ...[
        const SizedBox(width: 10),
        Expanded(
          child: _PriceCard(label: 'Niño', value: place.tarifaNino),
        ),
      ],
      if (_hasValue(place.tarifaExtranjero)) ...[
        const SizedBox(width: 10),
        Expanded(
          child: _PriceCard(label: 'Extranjero', value: place.tarifaExtranjero),
        ),
      ],
    ],
  );

  Widget _technicalLocation() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4EBE8)),
    ),
    child: ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.pin_drop_outlined, color: AppColors.primary),
      title: const Text(
        'Ubicación técnica',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      subtitle: const Text(
        'Coordenadas del registro oficial',
        style: TextStyle(fontSize: 11),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: [
        Row(
          children: [
            Expanded(child: Text('Latitud\n${place.latitud}')),
            Expanded(child: Text('Longitud\n${place.longitud}')),
          ],
        ),
      ],
    ),
  );
}

class _ProgressivePlaceGallery extends StatefulWidget {
  const _ProgressivePlaceGallery({required this.place, required this.photos});

  final TouristPlaceModel place;
  final GooglePlacesService photos;

  @override
  State<_ProgressivePlaceGallery> createState() =>
      _ProgressivePlaceGalleryState();
}

class _ProgressivePlaceGalleryState extends State<_ProgressivePlaceGallery> {
  late final Future<List<TouristGalleryPhoto>> _gallery;
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _gallery = widget.photos.getTouristGallery(
      name: widget.place.nombre,
      lat: widget.place.latitud,
      lng: widget.place.longitud,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _prefetchNext(List<TouristGalleryPhoto> gallery, int index) {
    final next = index + 1;
    if (next >= gallery.length) return;
    precacheImage(
      NetworkImage(
        gallery[next].thumbnailUrl,
        headers: widget.photos.headersFor(gallery[next]),
      ),
      context,
    );
  }

  void _openViewer(List<TouristGalleryPhoto> gallery, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoGalleryViewer(
          placeName: widget.place.nombre,
          photos: gallery,
          service: widget.photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<TouristGalleryPhoto>>(
        future: _gallery,
        builder: (context, snapshot) {
          final gallery = snapshot.data ?? const <TouristGalleryPhoto>[];
          if (gallery.isEmpty) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _GalleryLoading();
            }
            return const _PhotoFallback();
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: gallery.length,
                onPageChanged: (index) {
                  setState(() => _current = index);
                  _prefetchNext(gallery, index);
                },
                itemBuilder: (_, index) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openViewer(gallery, index),
                  child: _ProgressiveNetworkPhoto(
                    photo: gallery[index],
                    service: widget.photos,
                    large: false,
                  ),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                        Colors.black45,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .45, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 18,
                child: _GallerySourceBadge(photo: gallery[_current]),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Material(
                  color: Colors.black.withValues(alpha: .58),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _openViewer(gallery, _current),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${_current + 1} / ${gallery.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _ProgressiveNetworkPhoto extends StatelessWidget {
  const _ProgressiveNetworkPhoto({
    required this.photo,
    required this.service,
    required this.large,
  });

  final TouristGalleryPhoto photo;
  final GooglePlacesService service;
  final bool large;

  @override
  Widget build(BuildContext context) => Image.network(
    large ? photo.largeUrl : photo.thumbnailUrl,
    headers: service.headersFor(photo),
    fit: large ? BoxFit.contain : BoxFit.cover,
    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded) return child;
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: child,
      );
    },
    loadingBuilder: (context, child, progress) =>
        progress == null ? child : const _GalleryLoading(),
    errorBuilder: (_, __, ___) => const _PhotoFallback(),
  );
}

class _GalleryLoading extends StatelessWidget {
  const _GalleryLoading();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFDCE8E2),
    alignment: Alignment.center,
    child: const SizedBox.square(
      dimension: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: AppColors.primary,
      ),
    ),
  );
}

class _GallerySourceBadge extends StatelessWidget {
  const _GallerySourceBadge({required this.photo});

  final TouristGalleryPhoto photo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .52),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          photo.isCommunity
              ? Icons.verified_user_outlined
              : Icons.travel_explore_rounded,
          color: Colors.white,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          photo.attribution,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PhotoGalleryViewer extends StatefulWidget {
  const _PhotoGalleryViewer({
    required this.placeName,
    required this.photos,
    required this.service,
    required this.initialIndex,
  });

  final String placeName;
  final List<TouristGalleryPhoto> photos;
  final GooglePlacesService service;
  final int initialIndex;

  @override
  State<_PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<_PhotoGalleryViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF08120F),
    appBar: AppBar(
      backgroundColor: const Color(0xFF08120F),
      foregroundColor: Colors.white,
      title: Text(
        widget.placeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Text(
              '${_current + 1} de ${widget.photos.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
    body: Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (index) => setState(() => _current = index),
          itemBuilder: (_, index) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: _ProgressiveNetworkPhoto(
                photo: widget.photos[index],
                service: widget.service,
                large: true,
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 30,
          child: _GallerySourceBadge(photo: widget.photos[_current]),
        ),
      ],
    ),
  );
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.place});
  final TouristPlaceModel place;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    TravelLibraryService.instance.isFavorite(widget.place.id).then((value) {
      if (mounted) setState(() => _favorite = value);
    });
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _favorite ? 'Quitar de favoritos' : 'Guardar lugar',
    onPressed: () async {
      final added = await TravelLibraryService.instance.toggleFavorite(
        widget.place,
      );
      if (!context.mounted) return;
      setState(() => _favorite = added);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Lugar guardado para consultarlo después.'
                : 'Lugar eliminado de favoritos.',
          ),
        ),
      );
    },
    icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
  );
}

class _AddToTripButton extends StatefulWidget {
  const _AddToTripButton({required this.place});
  final TouristPlaceModel place;

  @override
  State<_AddToTripButton> createState() => _AddToTripButtonState();
}

class _AddToTripButtonState extends State<_AddToTripButton> {
  bool _added = false;

  @override
  void initState() {
    super.initState();
    TravelLibraryService.instance.trip().then((places) {
      if (!mounted) return;
      setState(() => _added = places.any((item) => item.id == widget.place.id));
    });
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _added
        ? null
        : () async {
            final added = await TravelLibraryService.instance.addToTrip(
              widget.place,
            );
            if (!context.mounted) return;
            setState(() => _added = added || _added);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Agregado a Mi viaje.')),
            );
          },
    icon: Icon(_added ? Icons.check_rounded : Icons.add_road_rounded),
    label: Text(_added ? 'En mi viaje' : 'Mi viaje'),
  );
}

class _WeatherSafetyCard extends StatelessWidget {
  const _WeatherSafetyCard({required this.place});
  final TouristPlaceModel place;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: WeatherService().forecast(
      latitude: place.latitud,
      longitude: place.longitud,
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _InfoLoadingCard(label: 'Consultando clima y seguridad…');
      }
      if (snapshot.hasError || snapshot.data == null) {
        return const _SafetyFallback();
      }
      final current = Map<String, dynamic>.from(
        snapshot.data!['current'] as Map? ?? const {},
      );
      final temperature = (current['temperature_2m'] as num?)?.toDouble();
      final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;
      final precipitation = (current['precipitation'] as num?)?.toDouble() ?? 0;
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;
      final caution = wind >= 35 || precipitation > 2 || code >= 80;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: caution ? const Color(0xFFFFF1E4) : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              caution ? Icons.warning_amber_rounded : _weatherIcon(code),
              color: caution ? AppColors.warning : AppColors.primary,
              size: 30,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caution ? 'Visita con precaución' : _weatherLabel(code),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${temperature?.toStringAsFixed(0) ?? '--'} °C · Viento ${wind.toStringAsFixed(0)} km/h${precipitation > 0 ? ' · Lluvia ${precipitation.toStringAsFixed(1)} mm' : ''}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Pronóstico: Open-Meteo · Confirma condiciones locales antes de salir.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  static IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_outlined;
    if (code <= 3) return Icons.cloud_outlined;
    if (code <= 48) return Icons.foggy;
    if (code <= 67) return Icons.water_drop_outlined;
    if (code <= 77) return Icons.ac_unit_rounded;
    return Icons.thunderstorm_outlined;
  }

  static String _weatherLabel(int code) {
    if (code == 0) return 'Cielo despejado';
    if (code <= 3) return 'Parcialmente nublado';
    if (code <= 48) return 'Neblina en la zona';
    if (code <= 67) return 'Lluvia en la zona';
    if (code <= 77) return 'Condiciones de nieve';
    return 'Tormentas posibles';
  }
}

class _InfoLoadingCard extends StatelessWidget {
  const _InfoLoadingCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textLight)),
      ],
    ),
  );
}

class _SafetyFallback extends StatelessWidget {
  const _SafetyFallback();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1E4),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.health_and_safety_outlined, color: AppColors.warning),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Clima no disponible. Revisa las condiciones locales, lleva agua y avisa tu recorrido.',
            style: TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
      ],
    ),
  );
}

class _NearbyServicesSection extends StatefulWidget {
  const _NearbyServicesSection({required this.place});
  final TouristPlaceModel place;

  @override
  State<_NearbyServicesSection> createState() => _NearbyServicesSectionState();
}

class _NearbyServicesSectionState extends State<_NearbyServicesSection> {
  final _service = GooglePlacesService();
  late final Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final results = await Future.wait([
      _byType('restaurant', 'Restaurante'),
      _byType('lodging', 'Hospedaje'),
      _byType('pharmacy', 'Farmacia'),
    ]);
    return results.expand((items) => items.take(2)).toList();
  }

  Future<List<Map<String, dynamic>>> _byType(String type, String label) async {
    final items = await _service.getNearbyPlaces(
      lat: widget.place.latitud,
      lng: widget.place.longitud,
      type: type,
      radius: 5000,
    );
    return items.map((item) => {...item, '_type_label': label}).toList();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _InfoLoadingCard(
              label: 'Buscando servicios cercanos…',
            );
          }
          final services = snapshot.data ?? const [];
          if (services.isEmpty) {
            return const Text(
              'No encontramos servicios registrados en un radio de 5 km.',
              style: TextStyle(color: AppColors.textLight),
            );
          }
          return SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _serviceCard(services[index]),
            ),
          );
        },
      );

  Widget _serviceCard(Map<String, dynamic> service) {
    final name =
        (service['displayName'] as Map?)?['text']?.toString() ??
        'Servicio cercano';
    final location = service['location'] as Map?;
    final lat = location?['latitude'];
    final lng = location?['longitude'];
    return InkWell(
      onTap: lat == null || lng == null
          ? null
          : () => launchUrl(
              Uri.https('www.google.com', '/maps/dir/', {
                'api': '1',
                'destination': '$lat,$lng',
                'dir_action': 'navigate',
              }),
              mode: LaunchMode.externalApplication,
            ),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 180,
        padding: const EdgeInsets.all(14),
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
                const Icon(Icons.storefront_outlined, color: AppColors.primary),
                const Spacer(),
                if (service['rating'] != null)
                  Text(
                    '★ ${service['rating']}',
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              service['_type_label'].toString(),
              style: const TextStyle(color: AppColors.textLight, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.place});
  final TouristPlaceModel place;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reviews = await TravelLibraryService.instance.reviews(
      widget.place.id,
    );
    if (mounted) setState(() => _reviews = reviews);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(child: _SectionTitle('Opiniones de visita')),
          TextButton.icon(
            onPressed: _addReview,
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('Opinar'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (_reviews.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Sé la primera persona en guardar una opinión sobre este lugar.',
            style: TextStyle(color: AppColors.textLight),
          ),
        )
      else
        ..._reviews
            .take(3)
            .map(
              (review) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '★' * ((review['rating'] as num?)?.toInt() ?? 0),
                          style: const TextStyle(color: Color(0xFFF2A93B)),
                        ),
                        const Spacer(),
                        if (review['visit_verified'] == true)
                          const Text(
                            '✓ Visita verificada',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(review['comment']?.toString() ?? ''),
                  ],
                ),
              ),
            ),
      const SizedBox(height: 4),
      const Text(
        'Las opiniones se guardan en este dispositivo y estarán disponibles sin conexión.',
        style: TextStyle(color: AppColors.textLight, fontSize: 9),
      ),
    ],
  );

  Future<void> _addReview() async {
    var rating = 5;
    final controller = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tu opinión'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setDialogState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF2A93B),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '¿Qué debería saber otro viajero?',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    final comment = controller.text.trim();
    controller.dispose();
    if (accepted != true || comment.isEmpty) return;
    var verified = false;
    try {
      final position = await LocationService.getCurrentLocation();
      verified =
          Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            widget.place.latitud,
            widget.place.longitud,
          ) <=
          250;
    } catch (_) {}
    await TravelLibraryService.instance.addReview(
      placeId: widget.place.id,
      rating: rating,
      comment: comment,
      visitVerified: verified,
    );
    await _load();
  }
}

class _OfficialBadge extends StatelessWidget {
  const _OfficialBadge();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: AppColors.primary, size: 15),
          SizedBox(width: 5),
          Text(
            'Registro oficial MINCETUR',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.primarySoft,
    child: Center(
      child: Icon(Icons.landscape_rounded, size: 72, color: AppColors.primary),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textDark,
      fontSize: 21,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 104),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4EBE8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
