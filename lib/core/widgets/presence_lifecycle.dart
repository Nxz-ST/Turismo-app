import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/presence_service.dart';
import '../../features/places/services/report_place_service.dart';

class PresenceLifecycle extends StatefulWidget {
  const PresenceLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<PresenceLifecycle> createState() => _PresenceLifecycleState();
}

class _PresenceLifecycleState extends State<PresenceLifecycle>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _synchronizePending();
      }
    });
    _record('app_open');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _record('app_resume');
  }

  Future<void> _record(String source) async {
    try {
      await PresenceService.instance.record(source: source);
    } catch (_) {
      // GPS y red son complementarios: un fallo no bloquea la navegación.
    }
    await _synchronizePending();
  }

  Future<void> _synchronizePending() async {
    final count = await ReportPlaceService().syncPending();
    if (!mounted || count == 0) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? 'Tu aporte pendiente se envió correctamente.'
              : 'Se enviaron $count aportes pendientes.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
