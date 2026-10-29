import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/exploration_context_service.dart';

Future<bool> showExplorationAreaPicker(BuildContext context) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ExplorationAreaPicker(),
  );
  return changed ?? false;
}

class _ExplorationAreaPicker extends StatefulWidget {
  const _ExplorationAreaPicker();

  @override
  State<_ExplorationAreaPicker> createState() => _ExplorationAreaPickerState();
}

class _ExplorationAreaPickerState extends State<_ExplorationAreaPicker> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<ExplorationArea> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 420), () async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final items = await ExplorationContextService.instance.search(value);
        if (mounted) setState(() => _results = items);
      } catch (_) {
        if (mounted) {
          setState(() => _error = 'No pudimos buscar destinos ahora.');
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _select(ExplorationArea area) async {
    final scope = await _chooseScope(area);
    if (scope == null) return;
    await ExplorationContextService.instance.select(
      area.copyWith(scope: scope),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<String?> _chooseScope(ExplorationArea area) =>
      showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué deseas explorar?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  area.name,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                for (final option in const [
                  ('Ciudad', 'Solo el núcleo urbano y sus atractivos próximos'),
                  ('Alrededores', 'La ciudad, pueblos y lugares cercanos'),
                  ('Región', 'Un radio amplio para planificar varios días'),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.radar, color: AppColors.primary),
                    title: Text(
                      option.$1,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(option.$2),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, option.$1),
                  ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD3DDDA),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Elige dónde explorar',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Ej. Huaraz, Cusco o Chachapoyas',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.my_location, color: AppColors.primary),
            ),
            title: const Text(
              'Usar mi ubicación',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Mostrar lugares cercanos a ti ahora'),
            onTap: () async {
              await ExplorationContextService.instance.useCurrentLocation();
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (_, index) {
                final area = _results[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.location_city_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    area.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    area.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _select(area),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
