import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../services/user_profile_service.dart';
import '../traveler_profile_options.dart';

/// "Cuéntanos de ti": perfil de viajero opcional.
///
/// En modo [onboarding] aparece una vez tras registrarse y se puede omitir.
/// En modo edición se abre desde el perfil.
class TravelerProfileScreen extends StatefulWidget {
  const TravelerProfileScreen({
    super.key,
    this.initial,
    this.onboarding = false,
    this.onFinished,
  });

  final UserProfile? initial;
  final bool onboarding;
  final VoidCallback? onFinished;

  @override
  State<TravelerProfileScreen> createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen> {
  final _service = UserProfileService();
  String? _travelerType;
  String? _region;
  String? _country;
  String? _ageRange;
  final Set<String> _interests = {};
  String? _hiking;
  String? _referral;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _travelerType = initial.travelerType;
      _region =
          TravelerProfileOptions.peruRegions.contains(initial.originRegion)
          ? initial.originRegion
          : null;
      _country =
          TravelerProfileOptions.countries.contains(initial.originCountry)
          ? initial.originCountry
          : null;
      _ageRange = initial.ageRange;
      _interests.addAll(initial.interests);
      _hiking = initial.hikingExperience;
      _referral = initial.referralSource;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final foreign = _travelerType == 'foreign';
      await _service.saveTravelerProfile(
        travelerType: _travelerType,
        originRegion: foreign ? null : _region,
        originCountry: foreign ? _country : null,
        ageRange: _ageRange,
        interests: _interests.toList(),
        hikingExperience: _hiking,
        referralSource: _referral,
      );
      if (!mounted) return;
      _finish(saved: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'No pudimos guardar tu perfil. Inténtalo nuevamente.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _skip() async {
    setState(() => _saving = true);
    try {
      await _service.skipOnboarding();
    } catch (_) {
      // Omitir nunca debe bloquear la entrada a la app.
    }
    if (!mounted) return;
    _finish(saved: false);
  }

  void _finish({required bool saved}) {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.pop(context, saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.onboarding
          ? null
          : AppBar(
              title: const Text('Mis datos de viajero'),
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (widget.onboarding) ...[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.waving_hand_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cuéntanos de ti',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Todo es opcional. Lo usamos para recomendarte lugares y rutas a tu medida y para estadísticas anónimas del piloto. Puedes cambiarlo cuando quieras desde tu perfil.',
                    style: TextStyle(
                      color: AppColors.textLight,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  _section('¿Qué tipo de viajero eres?'),
                  ...TravelerProfileOptions.travelerTypes.entries.map(
                    (entry) => _OptionCard(
                      title: entry.value,
                      subtitle:
                          TravelerProfileOptions.travelerTypeHints[entry.key]!,
                      selected: _travelerType == entry.key,
                      onTap: () => setState(
                        () => _travelerType = _travelerType == entry.key
                            ? null
                            : entry.key,
                      ),
                    ),
                  ),
                  if (_travelerType != null) ...[
                    const SizedBox(height: 6),
                    _dropdown(
                      label: _travelerType == 'foreign'
                          ? 'País de origen'
                          : 'Región donde vives',
                      value: _travelerType == 'foreign' ? _country : _region,
                      items: _travelerType == 'foreign'
                          ? TravelerProfileOptions.countries
                          : TravelerProfileOptions.peruRegions,
                      onChanged: (value) => setState(() {
                        if (_travelerType == 'foreign') {
                          _country = value;
                        } else {
                          _region = value;
                        }
                      }),
                    ),
                  ],
                  _section('Rango de edad'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TravelerProfileOptions.ageRanges
                        .map(
                          (range) => _chip(
                            label: range == '65+' ? '65 o más' : range,
                            selected: _ageRange == range,
                            onTap: () => setState(
                              () =>
                                  _ageRange = _ageRange == range ? null : range,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  _section(
                    '¿Qué te gusta hacer?',
                    hint: 'Elige los que quieras',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TravelerProfileOptions.interests.entries
                        .map(
                          (entry) => _chip(
                            label: entry.value.$1,
                            icon: entry.value.$2,
                            selected: _interests.contains(entry.key),
                            onTap: () => setState(() {
                              if (!_interests.remove(entry.key)) {
                                _interests.add(entry.key);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  _section(
                    'Experiencia en caminatas',
                    hint: 'Te avisaremos si una ruta es muy exigente',
                  ),
                  ...TravelerProfileOptions.hikingLevels.entries.map(
                    (entry) => _OptionCard(
                      title: entry.value.$1,
                      subtitle: entry.value.$2,
                      selected: _hiking == entry.key,
                      onTap: () => setState(
                        () => _hiking = _hiking == entry.key ? null : entry.key,
                      ),
                    ),
                  ),
                  _section('¿Cómo conociste RutaAmiga?'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TravelerProfileOptions.referralSources.entries
                        .map(
                          (entry) => _chip(
                            label: entry.value,
                            selected: _referral == entry.key,
                            onTap: () => setState(
                              () => _referral = _referral == entry.key
                                  ? null
                                  : entry.key,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: Color(0xFFE6E3DA))),
              ),
              child: Row(
                children: [
                  if (widget.onboarding) ...[
                    TextButton(
                      onPressed: _saving ? null : _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                        minimumSize: const Size(0, 54),
                      ),
                      child: const Text(
                        'Omitir',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.onboarding ? 'Continuar' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, {String? hint}) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ],
    ),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) => FilterChip(
    label: Text(label),
    avatar: icon == null
        ? null
        : Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : AppColors.primary,
          ),
    showCheckmark: false,
    selected: selected,
    onSelected: (_) => onTap(),
    labelStyle: TextStyle(
      fontWeight: FontWeight.w700,
      color: selected ? Colors.white : AppColors.textDark,
    ),
    backgroundColor: Colors.white,
    selectedColor: AppColors.primary,
    side: BorderSide(
      color: selected ? AppColors.primary : const Color(0xFFE3E1D9),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    key: ValueKey(label),
    value: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E1D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3E1D9)),
      ),
    ),
    items: items
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFFE3E1D9),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : const Color(0xFFB9BFBB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
