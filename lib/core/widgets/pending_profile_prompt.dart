import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../errors/friendly_error.dart';
import '../../features/places/services/report_place_service.dart';
import '../../features/places/screens/evidence_hub_screen.dart';
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
  static final Map<String, String> _knownStatuses = {};
  static final Set<String> _announcedTransitions = {};
  static bool _statusBaselineReady = false;
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
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _checking = true;
    try {
      final items = await _service.obtenerMisAportes(limit: 20);
      if (!mounted) return;
      _notifyStatusChanges(items);
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

  void _notifyStatusChanges(List<Map<String, dynamic>> items) {
    final current = <String, String>{};
    for (final item in items) {
      final id = item['id']?.toString();
      final status = item['status']?.toString();
      if (id == null || status == null || id.startsWith('local-')) continue;
      current[id] = status;
    }
    if (!_statusBaselineReady) {
      _knownStatuses
        ..clear()
        ..addAll(current);
      _statusBaselineReady = true;
      return;
    }
    const visibleResults = {
      'candidate',
      'needs_review',
      'duplicate',
      'validated',
      'rejected',
      'failed',
    };
    for (final entry in current.entries) {
      final previous = _knownStatuses[entry.key];
      final transition = '${entry.key}:$previous>${entry.value}';
      if (previous == null ||
          previous == entry.value ||
          !visibleResults.contains(entry.value) ||
          !_announcedTransitions.add(transition)) {
        continue;
      }
      final item = items.firstWhere(
        (candidate) => candidate['id']?.toString() == entry.key,
      );
      final name = item['name']?.toString() ?? 'Tu aporte';
      final message = switch (entry.value) {
        'validated' => '$name ya fue validado y está disponible en el mapa.',
        'duplicate' => '$name fue asociado a un lugar que ya existía.',
        'candidate' => '$name superó el análisis y pasará a revisión.',
        'needs_review' => '$name necesita una revisión final.',
        'rejected' => '$name no fue aprobado. Puedes revisar el motivo.',
        _ => 'No pudimos completar el análisis de $name.',
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const EvidenceHubScreen()),
              ),
            ),
          ),
        );
      });
    }
    _knownStatuses.addAll(current);
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
      HapticFeedback.mediumImpact();
      final openContributions = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.verified_rounded,
            color: Color(0xFF15856B),
            size: 42,
          ),
          title: const Text('¡Tu descubrimiento está completo!'),
          content: Text(
            'La información de ${item['name'] ?? 'este lugar'} ya forma parte de su ficha comunitaria.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Seguir explorando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ver mis aportes'),
            ),
          ],
        ),
      );
      if (openContributions == true && mounted) {
        await Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute(builder: (_) => const EvidenceHubScreen()));
      }
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
