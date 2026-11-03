import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../models/existing_place_target.dart';
import '../models/tourist_place_model.dart';
import '../services/report_place_service.dart';
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
  final _reportService = ReportPlaceService();
  final _search = TextEditingController();
  late Future<List<ExistingPlaceTarget>> _future;
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

  Future<List<ExistingPlaceTarget>> _load() async {
    final position = await LocationService.getCurrentLocation();
    final officialFuture = _service.obtenerLugaresCercanos(
      latitud: position.latitude,
      longitud: position.longitude,
      radio: 50000,
    );
    final communityFuture = _reportService
        .obtenerReportesCercanos(
          latitud: position.latitude,
          longitud: position.longitude,
          radio: 50000,
        )
        .catchError((_) => <Map<String, dynamic>>[]);
    final results = await Future.wait([officialFuture, communityFuture]);
    final official = results[0]
        .map(
          (row) => ExistingPlaceTarget.fromOfficial(
            TouristPlaceModel.fromSupabase(row),
          ),
        )
        .toList();
    final community = results[1]
        .map(ExistingPlaceTarget.fromCommunity)
        .toList();
    return [...community, ...official];
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
          child: FutureBuilder<List<ExistingPlaceTarget>>(
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
                        '${place.name} ${place.district} ${place.province}'
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
                      leading: CircleAvatar(
                        backgroundColor: place.isCommunity
                            ? const Color(0xFFF0E8F6)
                            : AppColors.primarySoft,
                        child: Icon(
                          place.isCommunity
                              ? Icons.people_alt_outlined
                              : Icons.verified_outlined,
                          color: place.isCommunity
                              ? const Color(0xFF7655A6)
                              : AppColors.primary,
                        ),
                      ),
                      title: Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        place.isCommunity
                            ? 'Descubrimiento comunitario · ${place.category}'
                            : '${place.district}, ${place.province}',
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
