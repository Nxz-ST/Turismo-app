import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../places/models/tourist_place_model.dart';
import '../../places/screens/community_place_detail_screen.dart';
import '../../places/screens/tourist_place_detail_screen.dart';
import '../../places/services/weather_service.dart';
import '../services/travel_library_service.dart';

class PlaceComparisonScreen extends StatefulWidget {
  const PlaceComparisonScreen({super.key});

  @override
  State<PlaceComparisonScreen> createState() => _PlaceComparisonScreenState();
}

class _PlaceComparisonScreenState extends State<PlaceComparisonScreen> {
  List<TouristPlaceModel> _places = const [];
  final Set<String> _selected = {};
  final Map<String, Map<String, dynamic>?> _weather = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final places = await TravelLibraryService.instance.favorites();
    _selected.addAll(places.take(3).map((place) => place.libraryKey));
    if (!mounted) return;
    setState(() {
      _places = places;
      _loading = false;
    });
    await _refreshWeather();
  }

  Future<void> _refreshWeather() async {
    for (final place in _chosen) {
      try {
        _weather[place.libraryKey] = await WeatherService().forecast(
          latitude: place.latitud,
          longitude: place.longitud,
        );
      } catch (_) {
        _weather[place.libraryKey] = null;
      }
      if (mounted) setState(() {});
    }
  }

  List<TouristPlaceModel> get _chosen => _places
      .where((place) => _selected.contains(place.libraryKey))
      .take(3)
      .toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comparar destinos')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _places.isEmpty
        ? const _ComparisonEmpty()
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Elige hasta 3 lugares',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Compara clima, altitud, acceso y procedencia antes de decidir.',
                style: TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final place in _places)
                    FilterChip(
                      selected: _selected.contains(place.libraryKey),
                      label: Text(place.nombre),
                      onSelected: (selected) async {
                        if (selected && _selected.length >= 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Puedes comparar hasta 3 lugares.'),
                            ),
                          );
                          return;
                        }
                        setState(
                          () => selected
                              ? _selected.add(place.libraryKey)
                              : _selected.remove(place.libraryKey),
                        );
                        await _refreshWeather();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 22),
              if (_chosen.length < 2)
                const _ComparisonHint()
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final place in _chosen) ...[
                        _destinationCard(place),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
            ],
          ),
  );

  Widget _destinationCard(TouristPlaceModel place) {
    final current = Map<String, dynamic>.from(
      _weather[place.libraryKey]?['current'] as Map? ?? const {},
    );
    final temperature = (current['temperature_2m'] as num?)?.round();
    return SizedBox(
      width: 235,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _open(place),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: place.source == 'community'
                      ? const Color(0xFFF0E8F8)
                      : AppColors.primarySoft,
                  child: Icon(
                    place.source == 'community'
                        ? Icons.people_alt_outlined
                        : Icons.verified_outlined,
                    color: place.source == 'community'
                        ? const Color(0xFF7655A6)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  place.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _metric(
                  Icons.thermostat_outlined,
                  'Clima',
                  temperature == null ? 'No disponible' : '$temperature °C',
                ),
                _metric(
                  Icons.height_rounded,
                  'Altitud',
                  place.altitud <= 0
                      ? 'Sin dato'
                      : '${place.altitud.round()} m',
                ),
                _metric(Icons.category_outlined, 'Categoría', place.categoria),
                _metric(
                  Icons.payments_outlined,
                  'Ingreso',
                  place.tipoIngreso.trim().isEmpty
                      ? 'Por confirmar'
                      : place.tipoIngreso,
                ),
                _metric(
                  Icons.shield_outlined,
                  'Fuente',
                  place.source == 'community' ? 'Comunidad' : 'MINCETUR',
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver lugar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _open(TouristPlaceModel place) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => place.source == 'community'
          ? CommunityPlaceDetailScreen(initialPlace: place.toCommunityJson())
          : TouristPlaceDetailScreen(place: place, distance: 0),
    ),
  );
}

class _ComparisonHint extends StatelessWidget {
  const _ComparisonHint();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.compare_arrows_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(child: Text('Selecciona al menos dos lugares guardados.')),
        ],
      ),
    ),
  );
}

class _ComparisonEmpty extends StatelessWidget {
  const _ComparisonEmpty();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(36),
      child: Text(
        'Guarda al menos dos destinos para poder compararlos.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
