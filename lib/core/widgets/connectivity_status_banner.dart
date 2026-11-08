import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Estado global de red. Solo ocupa espacio cuando hay algo que comunicar.
class ConnectivityStatusBanner extends StatefulWidget {
  const ConnectivityStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityStatusBanner> createState() =>
      _ConnectivityStatusBannerState();
}

class _ConnectivityStatusBannerState extends State<ConnectivityStatusBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;
  bool _showRestored = false;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update);
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty ||
        results.every((item) => item == ConnectivityResult.none);
    if (!mounted || offline == _offline) return;
    final wasOffline = _offline;
    setState(() {
      _offline = offline;
      _showRestored = wasOffline && !offline;
    });
    _restoredTimer?.cancel();
    if (!offline) {
      _restoredTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showRestored = false);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: widget.child),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: !_offline && !_showRestored
            ? const SizedBox.shrink()
            : Material(
                key: ValueKey(_offline),
                color: _offline
                    ? const Color(0xFF3D4542)
                    : const Color(0xFF087B60),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _offline
                              ? Icons.cloud_off_outlined
                              : Icons.cloud_done_outlined,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _offline
                                ? 'Sin conexión · tus cambios se conservarán para sincronizar'
                                : 'Conexión recuperada · contenido actualizado',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    ],
  );
}
