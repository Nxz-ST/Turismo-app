import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../profile/services/user_profile_service.dart';
import '../legal_info.dart';
import '../widgets/consent_checkboxes.dart';

/// Se muestra a cuentas que aún no aceptaron la versión vigente de los
/// Términos y la Política (cuentas creadas antes, o una versión nueva).
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({
    super.key,
    required this.onAccepted,
    required this.onSignOut,
    this.isUpdate = false,
  });

  final VoidCallback onAccepted;
  final VoidCallback onSignOut;
  final bool isUpdate;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _service = UserProfileService();
  bool _accepted = false;
  bool _research = false;
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await _service.acceptTerms(
        version: LegalInfo.termsVersion,
        researchConsent: _research,
      );
      if (!mounted) return;
      widget.onAccepted();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback:
                  'No pudimos registrar tu aceptación. Revisa tu conexión.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isUpdate
                        ? 'Actualizamos nuestros términos'
                        : 'Antes de continuar',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Queremos que sepas cómo cuidamos tus datos.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 15),
                  ),
                  const SizedBox(height: 22),
                  const _Point(
                    Icons.photo_camera_outlined,
                    'Tus fotos validan lugares',
                    'Un sistema las analiza y una persona del equipo las revisa antes de publicarlas.',
                  ),
                  const _Point(
                    Icons.groups_outlined,
                    'Se publican sin tu nombre',
                    'Las fotos aprobadas aparecen como “Comunidad RutaAmiga”.',
                  ),
                  const _Point(
                    Icons.location_off_outlined,
                    'Tu ubicación no es pública',
                    'Se publica la ubicación del lugar, nunca la tuya.',
                  ),
                  const _Point(
                    Icons.block_outlined,
                    'No vendemos tus datos',
                    'No hay publicidad. Puedes pedir ver o borrar tus datos cuando quieras.',
                  ),
                  const SizedBox(height: 10),
                  ConsentCheckboxes(
                    acceptedTerms: _accepted,
                    researchConsent: _research,
                    onTermsChanged: (value) =>
                        setState(() => _accepted = value),
                    onResearchChanged: (value) =>
                        setState(() => _research = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _accepted && !_saving ? _accept : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Aceptar y continuar'),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : widget.onSignOut,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textLight,
                    ),
                    child: const Text('Ahora no, cerrar sesión'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
