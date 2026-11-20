import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/account_suspension.dart';
import '../legal_info.dart';
import 'legal_document_screen.dart';

/// Se muestra cuando el equipo bloqueó la cuenta por incumplir los Términos
/// (sección 4). Solo permite leer los Términos, escribir al equipo o salir.
class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({
    super.key,
    required this.info,
    required this.onSignOut,
  });

  final AccountSuspensionInfo info;
  final VoidCallback onSignOut;

  String get _duration {
    final until = info.suspendedUntil;
    if (until == null) return 'El bloqueo es definitivo.';
    final d = until;
    String two(int v) => v.toString().padLeft(2, '0');
    return 'El bloqueo termina el ${two(d.day)}/${two(d.month)}/${d.year} '
        'a las ${two(d.hour)}:${two(d.minute)}.';
  }

  Future<void> _contact(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalInfo.contactEmail,
      queryParameters: {
        'subject': 'Revisión de bloqueo de cuenta - RutaAmiga',
        'body':
            'Hola, mi cuenta de RutaAmiga fue bloqueada y creo que es un error. ',
      },
    );
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escríbenos a ${LegalInfo.contactEmail}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = info.reason;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 40, 22, 20),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: AppColors.danger,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tu cuenta está bloqueada',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El equipo de RutaAmiga bloqueó tu cuenta por incumplir '
                    'los Términos y condiciones. $_duration',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: .25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Motivo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.danger,
                            letterSpacing: .3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (reason == null || reason.isEmpty)
                              ? 'Contenido prohibido o incumplimiento de los Términos.'
                              : reason,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Mientras dure el bloqueo no puedes usar la app ni subir '
                    'aportes. Si crees que es un error, escríbenos y '
                    'revisaremos tu caso.',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalDocumentScreen.terms(),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Leer los Términos y condiciones'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
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
                    child: FilledButton.icon(
                      onPressed: () => _contact(context),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Escribir al equipo'),
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
                    ),
                  ),
                  TextButton(
                    onPressed: onSignOut,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textLight,
                    ),
                    child: const Text('Cerrar sesión'),
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
