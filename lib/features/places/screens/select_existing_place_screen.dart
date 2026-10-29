import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../models/tourist_place_model.dart';
import '../services/tourist_place_service.dart';
import 'register_place_screen.dart';

class SelectExistingPlaceScreen extends StatefulWidget {
  const SelectExistingPlaceScreen({super.key});

  @override
  State<SelectExistingPlaceScreen> createState() =>
      _SelectExistingPlaceScreenState();
}

class _SelectExistingPlaceScreenState extends State<SelectExistingPlaceScreen> {
  final _service = TouristPlaceService();
  final _search = TextEditingController();
  late Future<List<TouristPlaceModel>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<TouristPlaceModel>> _load() async {
    final position = await LocationService.getCurrentLocation();
    final rows = await _service.obtenerLugaresCercanos(
      latitud: position.latitude,
      longitud: position.longitude,
      radio: 50000,
    );
    return rows.map(TouristPlaceModel.fromSupabase).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Elegir lugar existente')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            children: [
              const Text(
                'Busca el lugar que visitaste. Tu fotografía ayudará a mantener su información actualizada.',
                style: TextStyle(color: AppColors.textLight, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (value) =>
                    setState(() => _query = value.toLowerCase().trim()),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o distrito',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<TouristPlaceModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('No pudimos cargar lugares cercanos.'),
                );
              }
              final visible = (snapshot.data ?? const [])
                  .where(
                    (place) =>
                        _query.isEmpty ||
                        '${place.nombre} ${place.distrito} ${place.provincia}'
                            .toLowerCase()
                            .contains(_query),
                  )
                  .toList();
              if (visible.isEmpty) {
                return const Center(
                  child: Text('No encontramos coincidencias en esta zona.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (_, index) {
                  final place = visible[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(
                          Icons.verified_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        place.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${place.distrito}, ${place.provincia}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisterPlaceScreen(existingPlace: place),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
