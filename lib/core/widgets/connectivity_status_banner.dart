import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';

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
  Timer? _retryTimer;
  List<ConnectivityResult> _lastResults = const [];

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update);
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
  }

  Future<bool> _serverReachable() async {
    try {
      final base = AppEnvironment.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final response = await http
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 6));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<void> _update(List<ConnectivityResult> results) async {
    _lastResults = results;
    var offline =
        results.isEmpty ||
        results.every((item) => item == ConnectivityResult.none);
    // El plugin a veces informa "sin red" aunque sí la haya (p. ej. en el
    // simulador de iOS); el servidor tiene la última palabra.
    if (offline) offline = !await _serverReachable();
    if (!mounted) return;
    // Mientras se muestre "Sin conexión", se vuelve a comprobar cada 10 s.
    _retryTimer?.cancel();
    if (offline) {
      _retryTimer = Timer(
        const Duration(seconds: 10),
        () => _update(_lastResults),
      );
    }
    if (offline == _offline) return;
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
    _retryTimer?.cancel();
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
