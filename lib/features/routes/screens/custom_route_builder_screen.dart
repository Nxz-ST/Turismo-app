import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../../core/services/location_service.dart';
import '../../places/models/tourist_place_model.dart';
import '../../places/services/exploration_context_service.dart';
import '../../places/services/place_loader_service.dart';
import '../../places/services/tourist_place_service.dart';
import '../../places/widgets/exploration_area_picker.dart';
import '../../profile/services/travel_library_service.dart';

class CustomRouteBuilderScreen extends StatefulWidget {
  const CustomRouteBuilderScreen({super.key});

  @override
  State<CustomRouteBuilderScreen> createState() =>
      _CustomRouteBuilderScreenState();
}

class _CustomRouteBuilderScreenState extends State<CustomRouteBuilderScreen> {
  final _placesService = TouristPlaceService();
  final _library = TravelLibraryService.instance;
  final _searchController = TextEditingController();

  List<TouristPlaceModel> _places = const [];
  final List<TouristPlaceModel> _selected = [];
  bool _loading = true;
  String? _error;
  double _latitude = 0;
  double _longitude = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ExplorationContextService.instance.restore();
      final area = ExplorationContextService.instance.area;
      if (area != null) {
        _latitude = area.latitude;
        _longitude = area.longitude;
      } else {
        final position = await LocationService.getCurrentLocation();
        _latitude = position.latitude;
        _longitude = position.longitude;
      }
      final rows = await _placesService.obtenerLugaresCercanos(
        latitud: _latitude,
        longitud: _longitude,
        radio: math.min(area?.radius ?? 40000, 100000),
      );
      final current = await _library.trip();
      if (!mounted) return;
      setState(() {
        _places = rows
            .map(TouristPlaceModel.fromSupabase)
            .where(
              (place) =>
                  place.id > 0 &&
                  place.nombre.trim().isNotEmpty &&
                  place.coordinateQuality != 'approximate_cluster' &&
                  place.navigationLatitud.abs() <= 90 &&
                  place.navigationLongitud.abs() <= 180 &&
                  (place.navigationLatitud != 0 ||
                      place.navigationLongitud != 0),
            )
            .toList();
        _selected
          ..clear()
          ..addAll(
            current.where(
              (place) =>
                  place.coordinateQuality != 'approximate_cluster' &&
                  place.navigationLatitud.abs() <= 90 &&
                  place.navigationLongitud.abs() <= 180 &&
                  (place.navigationLatitud != 0 ||
                      place.navigationLongitud != 0),
            ),
          );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  List<TouristPlaceModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _places;
    return _places.where((place) {
      return '${place.nombre} ${place.categoria} ${place.distrito} ${place.provincia}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  bool _isSelected(TouristPlaceModel place) =>
      _selected.any((item) => item.id == place.id);

  void _toggle(TouristPlaceModel place) {
    setState(() {
      final index = _selected.indexWhere((item) => item.id == place.id);
      if (index >= 0) {
        _selected.removeAt(index);
      } else {
        _selected.add(place);
      }
    });
  }

  Future<void> _changeDestination() async {
    if (await showExplorationAreaPicker(context) && mounted) await _load();
  }

  Future<void> _save() async {
    if (_selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige al menos 2 lugares para crear una ruta.'),
        ),
      );
      return;
    }
    await _library.replaceTrip(_selected);
    if (mounted) Navigator.pop(context, true);
  }

  double get _distanceKm {
    if (_selected.length < 2) return 0;
    var total = 0.0;
    for (var index = 1; index < _selected.length; index++) {
      total += PlaceLoaderService.distanceMeters(
        _selected[index - 1].navigationLatitud,
        _selected[index - 1].navigationLongitud,
        _selected[index].navigationLatitud,
        _selected[index].navigationLongitud,
      );
    }
    return total / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final area = ExplorationContextService.instance.area;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea tu propia ruta'),
        actions: [
          TextButton(onPressed: _changeDestination, child: const Text('Zona')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _BuilderError(message: _error!, onRetry: _load)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explora ${area?.name ?? 'cerca de ti'}',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Elige los lugares que quieres conocer. Luego podrás cambiar su orden.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar atractivo, distrito o categoría',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selected.isNotEmpty)
                  _SelectedSummary(
                    selected: _selected,
                    distanceKm: _distanceKm,
                    onRemove: _toggle,
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (_, index) {
                      final place = _filtered[index];
                      final selected = _isSelected(place);
                      final distance = PlaceLoaderService.distanceMeters(
                        _latitude,
                        _longitude,
                        place.navigationLatitud,
                        place.navigationLongitud,
                      );
                      return _PlaceChoice(
                        place: place,
                        selected: selected,
                        order: selected
                            ? _selected.indexWhere(
                                    (item) => item.id == place.id,
                                  ) +
                                  1
                            : null,
                        distanceKm: distance / 1000,
                        onTap: () => _toggle(place),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE4EBE8))),
                ),
                child: FilledButton.icon(
                  onPressed: _selected.length >= 2 ? _save : null,
                  icon: const Icon(Icons.alt_route_rounded),
                  label: Text(
                    _selected.length >= 2
                        ? 'Organizar ${_selected.length} paradas'
                        : 'Elige al menos 2 lugares',
                  ),
                ),
              ),
            ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
    required this.selected,
    required this.distanceKm,
    required this.onRemove,
  });

  final List<TouristPlaceModel> selected;
  final double distanceKm;
  final ValueChanged<TouristPlaceModel> onRemove;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${selected.length} paradas elegidas',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (selected.length > 1)
              Text(
                '${distanceKm.toStringAsFixed(1)} km entre paradas',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 35,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selected.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, index) => InputChip(
              label: Text('${index + 1}. ${selected[index].nombre}'),
              onDeleted: () => onRemove(selected[index]),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlaceChoice extends StatelessWidget {
  const _PlaceChoice({
    required this.place,
    required this.selected,
    required this.order,
    required this.distanceKm,
    required this.onTap,
  });

  final TouristPlaceModel place;
  final bool selected;
  final int? order;
  final double distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFF0F8F5) : Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE3EAE7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Text(
                      '$order',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : const Icon(
                      Icons.add_location_alt_outlined,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.distrito} · ${distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.add_circle_outline,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    ),
  );
}

class _BuilderError extends StatelessWidget {
  const _BuilderError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_outlined, size: 60, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text(
            'No pudimos cargar los lugares',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
