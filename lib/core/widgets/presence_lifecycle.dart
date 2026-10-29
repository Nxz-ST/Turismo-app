import 'package:flutter/material.dart';

import '../services/presence_service.dart';

class PresenceLifecycle extends StatefulWidget {
  const PresenceLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<PresenceLifecycle> createState() => _PresenceLifecycleState();
}

class _PresenceLifecycleState extends State<PresenceLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
