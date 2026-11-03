import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

Future<Map<String, dynamic>?> showPlaceProfileQuestionnaire(
  BuildContext context, {
  required bool existingPlace,
  String? placeName,
  Map<String, dynamic>? initialAnswers,
}) => showModalBottomSheet<Map<String, dynamic>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  isDismissible: false,
  enableDrag: false,
  builder: (_) => _PlaceProfileQuestionnaire(
    existingPlace: existingPlace,
    placeName: placeName,
    initialAnswers: initialAnswers,
  ),
);

class _PlaceProfileQuestionnaire extends StatefulWidget {
  const _PlaceProfileQuestionnaire({
    required this.existingPlace,
    this.placeName,
    this.initialAnswers,
  });

  final bool existingPlace;
  final String? placeName;
  final Map<String, dynamic>? initialAnswers;

  @override
  State<_PlaceProfileQuestionnaire> createState() =>
      _PlaceProfileQuestionnaireState();
}

class _PlaceProfileQuestionnaireState
    extends State<_PlaceProfileQuestionnaire> {
  String accessType = 'unknown';
  String costType = 'unknown';
  String accessDifficulty = 'unknown';
  String placeState = 'unknown';
  final activities = <String>{};
  final services = <String>{};
  final risks = <String>{};

  @override
  void initState() {
    super.initState();
    final answers = widget.initialAnswers;
    if (answers == null) return;
    accessType = answers['access_type']?.toString() ?? accessType;
    costType = answers['cost_type']?.toString() ?? costType;
    accessDifficulty =
        answers['access_difficulty']?.toString() ?? accessDifficulty;
    placeState = answers['place_state']?.toString() ?? placeState;
    activities.addAll(_stringValues(answers['activities']));
    services.addAll(_stringValues(answers['services']));
    risks.addAll(_stringValues(answers['risks']));
  }

  Iterable<String> _stringValues(dynamic values) =>
      values is List ? values.map((value) => value.toString()) : const [];

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      18 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.existingPlace
                        ? 'Actualiza este lugar'
                        : 'Completa el descubrimiento',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.existingPlace
                        ? 'La fotografía coincide con ${widget.placeName ?? 'un lugar existente'}. Cuéntanos cómo está actualmente.'
                        : 'La fotografía superó la validación. Selecciona lo que observaste para crear una ficha confiable.',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Completar después',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              _singleQuestion(
                widget.existingPlace
                    ? '¿Cómo encontraste el lugar?'
                    : '¿El lugar estaba accesible?',
                placeState,
                const {
                  'open': 'Abierto',
                  'restricted': 'Restringido',
                  'closed': 'Cerrado',
                  'unknown': 'No lo sé',
                },
                (value) => setState(() => placeState = value),
              ),
              _singleQuestion(
                '¿Cómo se puede llegar?',
                accessType,
                const {
                  'walking': 'A pie',
                  'vehicle': 'Vehículo',
                  'public_transport': 'Transporte público',
                  'mixed': 'Acceso mixto',
                  'unknown': 'No lo sé',
                },
                (value) => setState(() => accessType = value),
              ),
              _singleQuestion(
                'Dificultad del acceso',
                accessDifficulty,
                const {
                  'easy': 'Fácil',
                  'moderate': 'Moderada',
                  'difficult': 'Difícil',
                  'unknown': 'No lo sé',
                },
                (value) => setState(() => accessDifficulty = value),
              ),
              _singleQuestion(
                '¿Se paga para ingresar?',
                costType,
                const {
                  'free': 'Gratuito',
                  'paid': 'Pagado',
                  'unknown': 'No lo sé',
                },
                (value) => setState(() => costType = value),
              ),
              _multipleQuestion(
                '¿Qué actividades observaste?',
                activities,
                const {
                  'photography': 'Fotografía',
                  'walking': 'Caminata',
                  'swimming': 'Baño',
                  'nature': 'Naturaleza',
                  'culture': 'Cultura',
                  'adventure': 'Aventura',
                  'relaxation': 'Descanso',
                },
              ),
              _multipleQuestion('Servicios disponibles', services, const {
                'restrooms': 'Baños',
                'parking': 'Estacionamiento',
                'food': 'Alimentación',
                'guide': 'Guía',
                'signage': 'Señalización',
                'none_observed': 'Ninguno observado',
              }),
              _multipleQuestion('Precauciones observadas', risks, const {
                'difficult_access': 'Acceso complicado',
                'slippery_surface': 'Piso resbaladizo',
                'strong_current': 'Corriente fuerte',
                'steep_drop': 'Desnivel',
                'low_signal': 'Poca señal',
                'none_observed': 'Ninguna observada',
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text(
              'Guardar información',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Completar después'),
        ),
      ],
    ),
  );

  Widget _singleQuestion(
    String title,
    String value,
    Map<String, String> options,
    ValueChanged<String> onSelected,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: options.entries
              .map(
                (option) => ChoiceChip(
                  label: Text(option.value),
                  selected: value == option.key,
                  onSelected: (_) => onSelected(option.key),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _multipleQuestion(
    String title,
    Set<String> selected,
    Map<String, String> options,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: options.entries
              .map(
                (option) => FilterChip(
                  label: Text(option.value),
                  selected: selected.contains(option.key),
                  onSelected: (enabled) => setState(() {
                    if (option.key.startsWith('none_') && enabled) {
                      selected.clear();
                    } else if (enabled) {
                      selected.removeWhere(
                        (value) => value.startsWith('none_'),
                      );
                    }
                    enabled
                        ? selected.add(option.key)
                        : selected.remove(option.key);
                  }),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  void _submit() => Navigator.pop(context, {
    'access_type': accessType,
    'cost_type': costType,
    'access_difficulty': accessDifficulty,
    'place_state': placeState,
    'activities': activities.toList(),
    'services': services.toList(),
    'risks': risks.toList(),
  });
}
