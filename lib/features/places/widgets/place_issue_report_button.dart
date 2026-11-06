import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/place_trust_service.dart';

class PlaceIssueReportButton extends StatelessWidget {
  const PlaceIssueReportButton({
    super.key,
    required this.source,
    required this.placeId,
    required this.placeName,
  });

  final String source;
  final String placeId;
  final String placeName;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: TextButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PlaceIssueReportSheet(
          source: source,
          placeId: placeId,
          placeName: placeName,
        ),
      ),
      icon: const Icon(Icons.report_outlined),
      label: const Text('Reportar un cambio o riesgo'),
    ),
  );
}

class _PlaceIssueReportSheet extends StatefulWidget {
  const _PlaceIssueReportSheet({
    required this.source,
    required this.placeId,
    required this.placeName,
  });

  final String source;
  final String placeId;
  final String placeName;

  @override
  State<_PlaceIssueReportSheet> createState() => _PlaceIssueReportSheetState();
}

class _PlaceIssueReportSheetState extends State<_PlaceIssueReportSheet> {
  final _details = TextEditingController();
  String? _type;
  bool _sending = false;
  String? _error;

  static const _options = <({String value, IconData icon, String label})>[
    (
      value: 'access_closed',
      icon: Icons.block_rounded,
      label: 'Acceso cerrado',
    ),
    (
      value: 'safety_risk',
      icon: Icons.warning_amber_rounded,
      label: 'Existe un riesgo',
    ),
    (
      value: 'wrong_location',
      icon: Icons.wrong_location_outlined,
      label: 'Ubicación incorrecta',
    ),
    (
      value: 'outdated_info',
      icon: Icons.update_rounded,
      label: 'Información desactualizada',
    ),
  ];

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_type == null) {
      setState(() => _error = 'Selecciona qué cambió en el lugar.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await PlaceTrustService().reportPlaceIssue(
        source: widget.source,
        placeId: widget.placeId,
        placeName: widget.placeName,
        issueType: _type!,
        details: _details.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reporte recibido. Lo revisaremos antes de actualizar la ficha.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'No pudimos enviar el reporte. Inténtalo nuevamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD2DAD7),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '¿Qué cambió en el lugar?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            widget.placeName,
            style: const TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<String>(
                value: option.value,
                groupValue: _type,
                onChanged: (value) => setState(() => _type = value),
                secondary: Icon(option.icon, color: AppColors.primary),
                title: Text(
                  option.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFDCE6E2)),
                ),
                tileColor: Colors.white,
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _details,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos qué observaste (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_sending ? 'Enviando…' : 'Enviar para revisión'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El reporte no modifica la ficha automáticamente. Primero será revisado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}
