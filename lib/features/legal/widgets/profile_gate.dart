import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../profile/screens/traveler_profile_screen.dart';
import '../../profile/services/user_profile_service.dart';
import '../legal_info.dart';
import '../screens/consent_screen.dart';

/// Antes de entrar a la app comprueba que la cuenta aceptó la versión vigente
/// de los Términos y la Política, y ofrece una vez el perfil de viajero.
///
/// Si el servidor no responde (sin conexión), deja pasar: el registro ya exige
/// la casilla y la comprobación se repite en la siguiente apertura.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key, required this.child});

  final Widget child;

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

enum _Stage { loading, consent, onboarding, ready }

class _ProfileGateState extends State<ProfileGate> {
  final _service = UserProfileService();
  _Stage _stage = _Stage.loading;
  UserProfile? _profile;
  bool _isUpdate = false;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;
  String get _cacheKey => 'rutaamiga_profile_gate_v1_$_userId';

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final userId = _userId;
    if (userId == null) return _set(_Stage.ready);
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(_cacheKey) == LegalInfo.termsVersion) {
      // Consulta en segundo plano: si la cuenta está bloqueada, el cliente
      // HTTP lo avisa y la app muestra la pantalla de bloqueo.
      _service.fetch().ignore();
      return _set(_Stage.ready);
    }

    UserProfile profile;
    try {
      profile = await _service.fetch().timeout(const Duration(seconds: 8));
    } catch (_) {
      return _set(_Stage.ready);
    }

    if (profile.termsVersion != LegalInfo.termsVersion) {
      // Quien aceptó al registrarse (guardado en su cuenta) no vuelve a ver
      // la pantalla: se copia esa aceptación a su perfil.
      final metadata =
          Supabase.instance.client.auth.currentUser?.userMetadata ?? const {};
      if (metadata['terms_version'] == LegalInfo.termsVersion) {
        try {
          profile = await _service.acceptTerms(
            version: LegalInfo.termsVersion,
            researchConsent: metadata['research_consent'] == true,
          );
        } catch (_) {
          return _set(_Stage.ready);
        }
      } else {
        _isUpdate = profile.termsVersion != null;
        return _set(_Stage.consent);
      }
    }

    if (profile.onboardingCompletedAt == null) {
      _profile = profile;
      return _set(_Stage.onboarding);
    }
    await _markReady();
  }

  Future<void> _markReady() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cacheKey, LegalInfo.termsVersion);
    _set(_Stage.ready);
  }

  void _set(_Stage stage) {
    if (mounted) setState(() => _stage = stage);
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.loading:
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      case _Stage.consent:
        return ConsentScreen(
          isUpdate: _isUpdate,
          onAccepted: () {
            setState(() => _stage = _Stage.loading);
            _resolve();
          },
          onSignOut: _signOut,
        );
      case _Stage.onboarding:
        return TravelerProfileScreen(
          initial: _profile,
          onboarding: true,
          onFinished: _markReady,
        );
      case _Stage.ready:
        return widget.child;
    }
  }
}
