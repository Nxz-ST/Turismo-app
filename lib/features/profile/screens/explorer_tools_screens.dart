import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';

class ExplorerJournalScreen extends StatefulWidget {
  const ExplorerJournalScreen({super.key});

  @override
  State<ExplorerJournalScreen> createState() => _ExplorerJournalScreenState();
}

class _ExplorerJournalScreenState extends State<ExplorerJournalScreen> {
  static const _key = 'rutaamiga_explorer_journal_v1';
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _entries = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final place = TextEditingController();
    final note = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva memoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: place,
              decoration: const InputDecoration(labelText: 'Lugar'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '¿Qué quieres recordar?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (save != true || place.text.trim().isEmpty) return;
    _entries.insert(0, {
      'place': place.text.trim(),
      'note': note.text.trim(),
      'date': DateTime.now().toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_entries));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diario de exploración')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.edit_note),
      label: const Text('Nueva memoria'),
    ),
    body: _entries.isEmpty
        ? const _ToolEmpty(
            icon: Icons.auto_stories_outlined,
            title: 'Tu historia empieza en el próximo viaje',
            message:
                'Guarda notas y recuerdos privados de los lugares que visites.',
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final item = _entries[index];
              final date = DateTime.tryParse(
                item['date'].toString(),
              )?.toLocal();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(
                          Icons.place_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['place'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            if (date != null)
                              Text(
                                '${date.day}/${date.month}/${date.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            if (item['note'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(item['note'].toString()),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}

class TripPreparationScreen extends StatefulWidget {
  const TripPreparationScreen({super.key});

  @override
  State<TripPreparationScreen> createState() => _TripPreparationScreenState();
}

class _TripPreparationScreenState extends State<TripPreparationScreen> {
  static const _key = 'rutaamiga_trip_checklist_v1';
  final _items = <String, bool>{
    'Agua y alimento': false,
    'Protección solar': false,
    'Abrigo o impermeable': false,
    'Batería y mapa descargado': false,
    'Documento y dinero': false,
    'Avisar el plan a alguien': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? const [];
    for (final key in _items.keys) {
      _items[key] = saved.contains(key);
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle(String key, bool? value) async {
    setState(() => _items[key] = value ?? false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _items.entries.where((e) => e.value).map((e) => e.key).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _items.values.where((value) => value).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Preparar recorrido')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$ready de ${_items.length} listos',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ready / _items.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Revisa también el clima, la altitud y el acceso antes de salir.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Lista esencial',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ..._items.entries.map(
            (entry) => Card(
              child: CheckboxListTile(
                value: entry.value,
                onChanged: (value) => _toggle(entry.key, value),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                activeColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.warning,
            ),
            title: Text(
              'Explora con responsabilidad',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              'No ingreses a zonas restringidas y respeta las indicaciones de comunidades y autoridades locales.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolEmpty extends StatelessWidget {
  const _ToolEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    ),
  );
}
