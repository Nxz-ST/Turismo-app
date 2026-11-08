import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../places/models/tourist_place_model.dart';
import '../../places/screens/tourist_place_detail_screen.dart';
import '../../places/services/google_places_service.dart';
import '../../places/services/place_loader_service.dart';
import '../services/travel_library_service.dart';

class PersonalizedRecommendationsScreen extends StatefulWidget {
  const PersonalizedRecommendationsScreen({super.key});

  @override
  State<PersonalizedRecommendationsScreen> createState() =>
      _PersonalizedRecommendationsScreenState();
}

class _PersonalizedRecommendationsScreenState
    extends State<PersonalizedRecommendationsScreen> {
  final _photos = GooglePlacesService();
  late Future<_RecommendationsData> _future = _load();

  Future<_RecommendationsData> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    final styles =
        preferences.getStringList('rutaamiga_travel_styles_v1_$userId') ??
        const ['Naturaleza', 'Mochilero'];
    final favorites = await TravelLibraryService.instance.favorites();
    final all = await PlaceLoaderService.loadPlaces();
    final favoriteTerms = favorites
        .expand(
          (place) =>
              '${place.categoria} ${place.descripcion} ${place.actividades}'
                  .toLowerCase()
                  .split(' '),
        )
        .where((value) => value.length > 4)
        .toSet();
    final scored =
        all
            .map((place) {
              final text =
                  '${place.nombre} ${place.categoria} ${place.descripcion} ${place.actividades}'
                      .toLowerCase();
              var score = 0;
              final reasons = <String>[];
              for (final style in styles) {
                final normalized = style.toLowerCase();
                final matches = switch (normalized) {
                  'naturaleza' => _contains(text, const [
                    'natural',
                    'bosque',
                    'cascada',
                    'laguna',
                    'playa',
                  ]),
                  'trekking' => _contains(text, const [
                    'trekking',
                    'caminata',
                    'sender',
                    'montaña',
                  ]),
                  'aventura' => _contains(text, const [
                    'aventura',
                    'canotaje',
                    'escalada',
                    'cascada',
                  ]),
                  'cultura' => _contains(text, const [
                    'cultural',
                    'arqueol',
                    'museo',
                    'iglesia',
                    'históric',
                  ]),
                  'gastronomía' => _contains(text, const [
                    'gastronom',
                    'vino',
                    'pisco',
                  ]),
                  'familiar' =>
                    place.altitud < 3000 &&
                        !_contains(text, const ['escalada', 'nevado']),
                  'mochilero' => _contains(text, const [
                    'natural',
                    'caminata',
                    'mirador',
                    'bosque',
                  ]),
                  _ => false,
                };
                if (matches) {
                  score += 4;
                  reasons.add(style);
                }
              }
              final affinity = favoriteTerms.where(text.contains).length;
              score += affinity.clamp(0, 4);
              if (affinity > 0) reasons.add('similar a tus guardados');
              if (place.coordinateQuality == 'verified_correction') score += 1;
              return _ScoredPlace(place, score, reasons.toSet().toList());
            })
            .where((item) => item.score > 0)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    return _RecommendationsData(styles, scored.take(18).toList());
  }

  static bool _contains(String value, List<String> terms) =>
      terms.any(value.contains);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recomendado para ti')),
    body: FutureBuilder<_RecommendationsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppStateView.loading(
            message: 'Buscando lugares compatibles con tu estilo…',
          );
        }
        if (snapshot.hasError) {
          return AppStateView(
            icon: Icons.cloud_off_outlined,
            title: 'No pudimos preparar tus recomendaciones',
            message: 'Revisa tu conexión y vuelve a intentarlo.',
            actionLabel: 'Reintentar',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final data = snapshot.data;
        if (data == null || data.places.isEmpty) {
          return AppStateView(
            icon: Icons.travel_explore_outlined,
            title: 'Estamos aprendiendo tus gustos',
            message:
                'Guarda algunos lugares o actualiza tu estilo viajero para recibir mejores sugerencias.',
            actionLabel: 'Actualizar',
            onAction: () => setState(() => _future = _load()),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: data.places.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => index == 0
                ? _header(data.styles)
                : _card(data.places[index - 1]),
          ),
        );
      },
    ),
  );

  Widget _header(List<String> styles) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, Color(0xFF187A69)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Una selección que aprende de ti',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Usamos tu estilo (${styles.join(', ')}) y tus lugares guardados. No se comparte públicamente.',
          style: const TextStyle(color: Color(0xFFD7EEE6), height: 1.4),
        ),
      ],
    ),
  );

  Widget _card(_ScoredPlace item) {
    final place = item.place;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TouristPlaceDetailScreen(place: place, distance: 0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: FutureBuilder<String?>(
                    future: _photos.getTouristPhotoUrl(
                      name: place.nombre,
                      lat: place.latitud,
                      lng: place.longitud,
                    ),
                    builder: (_, photo) => AppNetworkImage(
                      url: photo.data ?? '',
                      headers: _photos.photoHeaders,
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
                      place.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${place.provincia}, ${place.departamento}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.reasons.isEmpty
                          ? 'Compatible con tu estilo'
                          : 'Porque te interesa ${item.reasons.take(2).join(' y ')}',
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
      ),
    );
  }
}

class _RecommendationsData {
  const _RecommendationsData(this.styles, this.places);
  final List<String> styles;
  final List<_ScoredPlace> places;
}

class _ScoredPlace {
  const _ScoredPlace(this.place, this.score, this.reasons);
  final TouristPlaceModel place;
  final int score;
  final List<String> reasons;
}
