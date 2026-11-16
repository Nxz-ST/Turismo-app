import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../profile/screens/traveler_profile_screen.dart';
import '../../profile/services/user_profile_service.dart';
import '../legal_info.dart';
import 'legal_document_screen.dart';

/// Perfil → Privacidad y consentimiento.
class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  final _service = UserProfileService();
  UserProfile? _profile;
  String? _error;
  bool _savingResearch = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profile = await _service.fetch();
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = friendlyErrorMessage(
          error,
          fallback: 'No pudimos cargar tus datos de privacidad.',
        ),
      );
    }
  }

  Future<void> _toggleResearch(bool value) async {
    setState(() => _savingResearch = true);
    try {
      final profile = await _service.setResearchConsent(value);
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(error, fallback: 'No se pudo guardar.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingResearch = false);
    }
  }

  Future<void> _requestDeletion() async {
    if (LegalInfo.contactEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El correo de contacto aún no está configurado. Escríbenos desde la universidad.',
          ),
        ),
      );
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: LegalInfo.contactEmail,
      queryParameters: {
        'subject': 'Solicitud de eliminación de datos - RutaAmiga',
        'body':
            'Hola, solicito la eliminación de mi cuenta y mis datos personales de RutaAmiga.',
      },
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escríbenos a ${LegalInfo.contactEmail}')),
      );
    }
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _editProfile() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TravelerProfileScreen(initial: _profile),
      ),
    );
    if (saved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacidad y consentimiento'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ConsentCard(profile: profile, error: _error, onRetry: _load),
            const SizedBox(height: 18),
            _title('Tus datos'),
            _tile(
              Icons.person_search_outlined,
              'Mis datos de viajero',
              profile == null
                  ? 'Tipo de viajero, origen, edad e intereses'
                  : profile.hasTravelerData
                  ? 'Toca para revisar o cambiar'
                  : 'Aún no los completaste (opcional)',
              _editProfile,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SwitchListTile(
                secondary: _icon(Icons.science_outlined),
                title: const Text(
                  'Uso en la investigación',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Tus aportes, anónimos y agregados, en la tesis de RutaAmiga',
                  style: TextStyle(fontSize: 11),
                ),
                value: profile?.researchConsent ?? false,
                onChanged: profile == null || _savingResearch
                    ? null
                    : _toggleResearch,
              ),
            ),
            const SizedBox(height: 10),
            _title('Documentos'),
            _tile(
              Icons.description_outlined,
              'Términos y condiciones',
              'Versión ${LegalInfo.termsVersion}',
              () => _open(const LegalDocumentScreen.terms()),
            ),
            _tile(
              Icons.privacy_tip_outlined,
              'Política de privacidad',
              'Qué datos usamos y para qué',
              () => _open(const LegalDocumentScreen.privacy()),
            ),
            const SizedBox(height: 10),
            _title('Tus derechos'),
            _tile(
              Icons.delete_outline,
              'Solicitar eliminación de mis datos',
              'Acceso, corrección o borrado (Ley 29733)',
              _requestDeletion,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppColors.textLight,
        letterSpacing: .3,
      ),
    ),
  );

  Widget _icon(IconData icon, {bool danger = false}) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: danger ? const Color(0xFFFFEEEE) : AppColors.primarySoft,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: danger ? AppColors.danger : AppColors.primary),
  );

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool danger = false,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      leading: _icon(icon, danger: danger),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: danger ? AppColors.danger : null,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.profile,
    required this.error,
    required this.onRetry,
  });

  final UserProfile? profile;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final accepted = profile?.termsAcceptedAt;
    final String title;
    final String detail;
    if (error != null) {
      title = 'Sin conexión con el servidor';
      detail = error!;
    } else if (profile == null) {
      title = 'Cargando…';
      detail = '';
    } else if (accepted != null) {
      title = 'Aceptaste la versión ${profile!.termsVersion}';
      detail =
          'Términos y Política de privacidad, el ${_date(accepted.toLocal())}.';
    } else {
      title = 'Aceptación registrada al crear tu cuenta';
      detail = 'Se sincronizará con tu perfil la próxima vez que abras la app.';
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF073B4C), Color(0xFF078B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (error != null)
            IconButton(
              tooltip: 'Reintentar',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
        ],
      ),
    );
  }

  static String _date(DateTime value) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}
