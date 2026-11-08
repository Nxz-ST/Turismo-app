import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../places/models/tourist_place_model.dart';
import '../../places/screens/community_place_detail_screen.dart';
import '../../places/screens/tourist_place_detail_screen.dart';
import '../../places/services/google_places_service.dart';
import '../services/travel_library_service.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final _library = TravelLibraryService.instance;
  final _photos = GooglePlacesService();
  late Future<List<TouristPlaceModel>> _future;
  bool _preparing = false;

  @override
  void initState() {
    super.initState();
    _future = _library.favorites();
  }

  void _reload() => setState(() {
    _future = _library.favorites();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lugares guardados')),
    body: FutureBuilder<List<TouristPlaceModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final places = snapshot.data ?? const [];
        if (places.isEmpty) {
          return const _EmptySaved();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          itemCount: places.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) =>
              index == 0 ? _offlineHeader(places) : _card(places[index - 1]),
        );
      },
    ),
  );

  Widget _card(TouristPlaceModel place) => InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => place.source == 'community'
            ? CommunityPlaceDetailScreen(initialPlace: place.toCommunityJson())
            : TouristPlaceDetailScreen(place: place, distance: 0),
      ),
    ).then((_) => _reload()),
    child: Ink(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 88,
              height: 88,
              child: place.source == 'community'
                  ? AppNetworkImage(url: place.primaryPhotoUrl)
                  : FutureBuilder<String?>(
                      future: _photos.getTouristPhotoUrl(
                        name: place.nombre,
                        lat: place.latitud,
                        lng: place.longitud,
                      ),
                      builder: (_, snapshot) => snapshot.data == null
                          ? const ColoredBox(
                              color: AppColors.primarySoft,
                              child: Icon(
                                Icons.landscape,
                                color: AppColors.primary,
                              ),
                            )
                          : AppNetworkImage(
                              url: snapshot.data!,
                              headers: _photos.photoHeaders,
                              fit: BoxFit.cover,
                            ),
                    ),
            ),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  place.source == 'community'
                      ? 'Descubrimiento comunitario · ${place.categoria}'
                      : '${place.provincia}, ${place.departamento}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.source == 'community'
                      ? 'Corroborado por RutaAmiga'
                      : 'Registro oficial MINCETUR',
                  style: TextStyle(
                    color: place.source == 'community'
                        ? const Color(0xFF7655A6)
                        : AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Icon(
                      Icons.offline_pin_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Ficha disponible sin conexión',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar de favoritos',
            onPressed: () async {
              await _library.toggleFavorite(place);
              _reload();
            },
            icon: const Icon(Icons.favorite, color: AppColors.danger),
          ),
        ],
      ),
    ),
  );

  Widget _offlineHeader(List<TouristPlaceModel> places) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.download_for_offline_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preparar sin conexión',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                'Conserva fichas, ubicaciones y fotografías consultadas.',
                style: TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _preparing ? null : () => _prepareOffline(places),
          child: Text(_preparing ? 'Preparando…' : 'Descargar'),
        ),
      ],
    ),
  );

  Future<void> _prepareOffline(List<TouristPlaceModel> places) async {
    setState(() => _preparing = true);
    var cached = 0;
    for (final place in places) {
      var url = place.primaryPhotoUrl;
      Map<String, String>? headers;
      if (url.isEmpty && place.source != 'community') {
        url =
            await _photos.getTouristPhotoUrl(
              name: place.nombre,
              lat: place.latitud,
              lng: place.longitud,
            ) ??
            '';
        headers = _photos.photoHeaders;
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
    setState(() => _preparing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contenido preparado: ${places.length} fichas y $cached fotografías.',
        ),
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64, color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Aún no guardaste lugares',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Usa el corazón de cada atractivo para encontrarlo aquí y consultar sus datos sin conexión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, height: 1.45),
          ),
        ],
      ),
    ),
  );
}
