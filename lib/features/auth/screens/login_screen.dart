import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../home/screens/home_screen.dart';
import '../../../core/widgets/presence_lifecycle.dart';
import '../services/auth_service.dart';
import '../../../core/widgets/pending_profile_prompt.dart';
import '../../legal/legal_info.dart';
import '../../legal/widgets/consent_checkboxes.dart';
import '../../legal/widgets/profile_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool obscurePassword = true;
  bool acceptedTerms = false;
  bool researchConsent = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _setMode(bool login) {
    if (login == isLogin || isLoading) return;
    HapticFeedback.selectionClick();
    setState(() => isLogin = login);
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe primero tu correo electrónico.')),
      );
      return;
    }
    try {
      await _authService.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te enviamos un enlace para recuperar tu contraseña.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'No pudimos enviar el enlace. Inténtalo nuevamente.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos requeridos.')),
      );
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa el formato de tu correo.')),
      );
      return;
    }
    if (!isLogin && !acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Para crear tu cuenta acepta los términos y la privacidad.',
          ),
        ),
      );
      return;
    }
    if (!isLogin && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    try {
      setState(() => isLoading = true);

      if (isLogin) {
        final response = await _authService.signIn(
          email: email,
          password: password,
        );
        if (response.session == null) {
          throw Exception('No se pudo crear una sesión válida.');
        }
      } else {
        final response = await _authService.signUp(
          email: email,
          password: password,
          name: name,
          termsVersion: LegalInfo.termsVersion,
          researchConsent: researchConsent,
        );
        if (response.session == null) {
          if (!mounted) return;
          setState(() => isLogin = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cuenta creada. Confirma tu correo antes de iniciar sesión.',
              ),
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PresenceLifecycle(
            child: ProfileGate(
              child: PendingProfilePrompt(child: HomeScreen()),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              e,
              fallback: 'No pudimos iniciar sesión. Revisa tus datos.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const _Hero(),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroHeader(
                          isLogin: isLogin,
                          canPop: Navigator.canPop(context),
                        ),
                        _sheet(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheet(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * .62,
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        24,
        22,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSwitch(isLogin: isLogin, onChanged: _setMode),
            const SizedBox(height: 22),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isLogin
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _Field(
                        label: 'Nombre',
                        controller: nameController,
                        hint: 'Cómo quieres que te llamemos',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                      ),
                    ),
            ),
            _Field(
              label: 'Correo electrónico',
              controller: emailController,
              hint: 'tu@correo.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Contraseña',
              controller: passwordController,
              hint: isLogin ? 'Tu contraseña' : 'Mínimo 6 caracteres',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              autofillHints: [
                isLogin ? AutofillHints.password : AutofillHints.newPassword,
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => isLoading ? null : _submit(),
              suffix: IconButton(
                tooltip: obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
            ),
            if (!isLogin) ...[
              const SizedBox(height: 14),
              ConsentCheckboxes(
                acceptedTerms: acceptedTerms,
                researchConsent: researchConsent,
                onTermsChanged: (value) =>
                    setState(() => acceptedTerms = value),
                onResearchChanged: (value) =>
                    setState(() => researchConsent = value),
              ),
            ],
            if (isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _resetPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              const SizedBox(height: 18),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: isLoading || (!isLogin && !acceptedTerms)
                    ? null
                    : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: .55,
                  ),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isLogin ? 'Iniciar sesión' : 'Crear cuenta'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isLogin
                        ? 'Tus aportes se publican como “Comunidad RutaAmiga”. Tu ubicación personal no se muestra a otros usuarios.'
                        : 'Usaremos tu correo solo para tu cuenta. Tus aportes se publican sin tu nombre.',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: MediaQuery.sizeOf(context).height * .48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF073B4C), Color(0xFF078B69)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -60,
            bottom: -10,
            child: Icon(
              Icons.landscape,
              size: 300,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
          Positioned(
            left: -40,
            bottom: 30,
            child: Icon(
              Icons.terrain,
              size: 180,
              color: Colors.white.withValues(alpha: .05),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isLogin, required this.canPop});

  final bool isLogin;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: canPop
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filled(
                      tooltip: 'Volver',
                      onPressed: () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .14),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.terrain, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'RutaAmiga',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(isLogin),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? 'Hola de nuevo' : 'Únete a la ruta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'Entra para seguir explorando y ver tus aportes.'
                      : 'Crea tu cuenta y ayuda a descubrir lugares del Perú.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
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

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: .5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _segment('Iniciar sesión', isLogin, () => onChanged(true)),
              _segment('Crear cuenta', !isLogin, () => onChanged(false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: selected ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE3E1D9)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: !obscureText,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA3ABA7),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
