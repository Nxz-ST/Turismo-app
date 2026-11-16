import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/legal_document_screen.dart';

/// Casilla obligatoria (mayoría de edad + Términos + Privacidad) y casilla
/// opcional de investigación. Ninguna viene marcada por defecto.
class ConsentCheckboxes extends StatefulWidget {
  const ConsentCheckboxes({
    super.key,
    required this.acceptedTerms,
    required this.researchConsent,
    required this.onTermsChanged,
    required this.onResearchChanged,
  });

  final bool acceptedTerms;
  final bool researchConsent;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onResearchChanged;

  @override
  State<ConsentCheckboxes> createState() => _ConsentCheckboxesState();
}

class _ConsentCheckboxesState extends State<ConsentCheckboxes> {
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _open(const LegalDocumentScreen.terms());
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _open(const LegalDocumentScreen.privacy());

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const link = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    return Column(
      children: [
        _ConsentRow(
          value: widget.acceptedTerms,
          onChanged: widget.onTermsChanged,
          text: TextSpan(
            children: [
              const TextSpan(text: 'Tengo 18 años o más y acepto los '),
              TextSpan(
                text: 'Términos y condiciones',
                style: link,
                recognizer: _termsTap,
              ),
              const TextSpan(text: ' y la '),
              TextSpan(
                text: 'Política de privacidad',
                style: link,
                recognizer: _privacyTap,
              ),
              const TextSpan(
                text:
                    '. Mis fotos y su ubicación se usarán para validar lugares y, si se aprueban, se publicarán como “Comunidad RutaAmiga”, sin mi nombre.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _ConsentRow(
          value: widget.researchConsent,
          onChanged: widget.onResearchChanged,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Opcional: ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text:
                    'acepto que mis aportes se usen, de forma anónima y agregada, en la investigación académica de RutaAmiga.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.text,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final InlineSpan text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      // Sin InkWell en toda la fila: el toque sobre los enlaces debe abrir
      // el documento, no marcar la casilla.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              height: 28,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text.rich(
                  text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
