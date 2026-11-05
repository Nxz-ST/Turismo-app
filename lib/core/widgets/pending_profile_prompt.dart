import 'dart:async';

import 'package:flutter/material.dart';

import '../errors/friendly_error.dart';
import '../../features/places/services/report_place_service.dart';
import '../../features/places/widgets/place_profile_questionnaire.dart';

/// Muestra el cuestionario apenas una contribución alcanza el estado validado.
///
/// Vive por encima de las pantallas de la aplicación para que el recordatorio
/// no dependa de que el usuario vuelva manualmente a la sección Aportar.
class PendingProfilePrompt extends StatefulWidget {
  const PendingProfilePrompt({super.key, required this.child});

  final Widget child;

  @override
  State<PendingProfilePrompt> createState() => _PendingProfilePromptState();
}

class _PendingProfilePromptState extends State<PendingProfilePrompt>
    with WidgetsBindingObserver {
  final _service = ReportPlaceService();
  final _promptedEvidenceIds = <String>{};
  Timer? _poller;
  bool _checking = false;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 700), _check);
    });
    _poller = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  bool _profileCompleted(Map<String, dynamic> item) {
    final events = item['processing_events'] as List? ?? const [];
    return events.any((event) {
      if (event is! Map || event['status']?.toString() != 'completed') {
        return false;
      }
      final metadata = event['metadata'];
      return event['stage']?.toString() == 'community_profile' ||
          (metadata is Map &&
              metadata['event_type']?.toString() == 'community_profile');
    });
  }

  Future<void> _check() async {
    if (!mounted || _checking || _showing) return;
    _checking = true;
    try {
      final items = await _service.obtenerMisAportes(limit: 20);
      if (!mounted) return;
      Map<String, dynamic>? pending;
      for (final item in items) {
        final id = item['id']?.toString();
        if (item['status']?.toString() == 'validated' &&
            id != null &&
            !id.startsWith('local-') &&
            !_promptedEvidenceIds.contains(id) &&
            !_profileCompleted(item)) {
          pending = item;
          break;
        }
      }
      if (pending == null || !mounted) return;
      await _showQuestionnaire(pending);
    } catch (_) {
      // El recordatorio no debe bloquear la navegación si no hay conexión.
    } finally {
      _checking = false;
    }
  }

  Future<void> _showQuestionnaire(Map<String, dynamic> item) async {
    final id = item['id'].toString();
    _promptedEvidenceIds.add(id);
    _showing = true;
    final snapshot = Map<String, dynamic>.from(
      item['target_place_snapshot'] as Map? ?? const {},
    );
    try {
      final answers = await showPlaceProfileQuestionnaire(
        context,
        useRootNavigator: true,
        existingPlace:
            item['contribution_type']?.toString() == 'existing_place',
        placeName:
            snapshot['nombre']?.toString() ??
            item['name']?.toString() ??
            'este lugar',
      );
      if (answers == null || !mounted) return;
      await _service.completeProfile(evidenceId: id, answers: answers);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Información guardada. La ficha del lugar ya fue actualizada.',
          ),
        ),
      );
    } catch (error) {
      _promptedEvidenceIds.remove(id);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    } finally {
      _showing = false;
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
