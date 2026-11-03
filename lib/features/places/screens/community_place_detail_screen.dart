import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/existing_place_target.dart';
import '../models/place_trust_model.dart';
import '../services/place_trust_service.dart';
import '../widgets/place_trust_passport_card.dart';
import 'register_place_screen.dart';

class CommunityPlaceDetailScreen extends StatefulWidget {
  const CommunityPlaceDetailScreen({super.key, required this.initialPlace});

  final Map<String, dynamic> initialPlace;

  @override
  State<CommunityPlaceDetailScreen> createState() =>
      _CommunityPlaceDetailScreenState();
}

class _CommunityPlaceDetailScreenState
    extends State<CommunityPlaceDetailScreen> {
  late final String _placeId = widget.initialPlace['id'].toString();
  late final Future<Map<String, dynamic>> _future = PlaceTrustService()
      .getCommunityPlace(_placeId)
      .catchError((_) => widget.initialPlace);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final place = snapshot.data ?? widget.initialPlace;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF62458C),
              foregroundColor: Colors.white,
              title: Text(
                place['nombre']?.toString() ?? 'Descubrimiento',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              flexibleSpace: FlexibleSpaceBar(background: _hero(place)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              sliver: SliverList.list(
                children: [
                  _communityBadge(),
                  const SizedBox(height: 12),
                  Text(
                    place['nombre']?.toString() ?? 'Descubrimiento',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _category(place),
                    style: const TextStyle(
                      color: Color(0xFF7655A6),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _actions(place),
                  const SizedBox(height: 24),
                  PlaceTrustPassportCard(
                    source: 'community',
                    placeId: _placeId,
                    initialTrust: _trust(place),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Información comunitaria',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _description(place),
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  if (_updates(place).isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Información aportada en campo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    for (final update in _updates(place).take(3))
                      _CommunityUpdateCard(update: update),
                  ],
                  const SizedBox(height: 24),
                  _location(place),
                  const SizedBox(height: 18),
                  const Text(
                    'Este lugar fue documentado por la comunidad. Su corroboración no equivale a un registro oficial ni garantiza que el acceso sea público.',
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
        );
      },
    ),
  );

  Widget _hero(Map<String, dynamic> place) {
    final photos = _photos(place);
    if (photos.isEmpty) return _heroFallback();
    return PageView.builder(
      itemCount: photos.length,
      itemBuilder: (_, index) => Image.network(
        photos[index],
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _heroFallback(),
      ),
    );
  }

  Widget _heroFallback() => Container(
    color: const Color(0xFFEDE5F4),
    alignment: Alignment.center,
    child: const Icon(
      Icons.landscape_outlined,
      size: 86,
      color: Color(0xFF7655A6),
    ),
  );

  Widget _communityBadge() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5F4),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF7655A6)),
          SizedBox(width: 6),
          Text(
            'DESCUBRIMIENTO COMUNITARIO',
            style: TextStyle(
              color: Color(0xFF7655A6),
              fontSize: 9,
              letterSpacing: .5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actions(Map<String, dynamic> place) => Row(
    children: [
      Expanded(
        child: FilledButton.icon(
          onPressed: () => _openDirections(place),
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Cómo llegar'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterPlaceScreen(
                existingPlace: ExistingPlaceTarget.fromCommunity(place),
              ),
            ),
          ),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Aportar'),
        ),
      ),
    ],
  );

  Widget _location(Map<String, dynamic> place) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4EBE8)),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${place['latitud']}, ${place['longitud']}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  PlaceTrustModel? _trust(Map<String, dynamic> place) {
    final raw = place['trust'];
    if (raw is! Map) return null;
    return PlaceTrustModel.fromJson(Map<String, dynamic>.from(raw));
  }

  String _category(Map<String, dynamic> place) =>
      place['categoria_ia']?.toString().trim().isNotEmpty == true
      ? place['categoria_ia'].toString()
      : 'Lugar natural';

  String _description(Map<String, dynamic> place) {
    final value = place['descripcion']?.toString().trim() ?? '';
    return value.isEmpty
        ? 'La ficha todavía necesita información de acceso, actividades y condiciones de visita. Puedes ayudar aportando evidencia desde el lugar.'
        : value;
  }

  List<String> _photos(Map<String, dynamic> place) {
    final values = <String>{};
    final primary = place['foto_url']?.toString().trim() ?? '';
    if (primary.isNotEmpty) values.add(primary);
    final raw = place['photos'];
    if (raw is List) {
      values.addAll(
        raw
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty),
      );
    }
    return values.toList();
  }

  List<Map<String, dynamic>> _updates(Map<String, dynamic> place) {
    final raw = place['community_updates'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _openDirections(Map<String, dynamic> place) async {
    final lat = double.tryParse(place['latitud']?.toString() ?? '');
    final lng = double.tryParse(place['longitud']?.toString() ?? '');
    if (lat == null || lng == null) return;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _CommunityUpdateCard extends StatelessWidget {
  const _CommunityUpdateCard({required this.update});

  final Map<String, dynamic> update;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4EBE8)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.fact_check_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            update['description']?.toString() ?? '',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
