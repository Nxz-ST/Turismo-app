import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../places/models/tourist_place_model.dart';
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
          itemCount: places.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _card(places[index]),
        );
      },
    ),
  );

  Widget _card(TouristPlaceModel place) => InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TouristPlaceDetailScreen(place: place, distance: 0),
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
              child: FutureBuilder<String?>(
                future: _photos.getTouristPhotoUrl(
                  name: place.nombre,
                  lat: place.latitud,
                  lng: place.longitud,
                ),
                builder: (_, snapshot) => snapshot.data == null
                    ? const ColoredBox(
                        color: AppColors.primarySoft,
                        child: Icon(Icons.landscape, color: AppColors.primary),
                      )
                    : Image.network(
                        snapshot.data!,
                        headers: _photos.photoHeaders,
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
                  '${place.provincia}, ${place.departamento}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Disponible sin conexión',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
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
