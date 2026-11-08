import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/app_accessibility_service.dart';
import '../core/widgets/pending_profile_prompt.dart';
import '../core/widgets/presence_lifecycle.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RutaAmigaApp extends StatelessWidget {
  const RutaAmigaApp({super.key, this.initialHome});

  final Widget? initialHome;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppAccessibilityService.instance,
      builder: (_, __) {
        final accessibility = AppAccessibilityService.instance;
        final base = AppTheme.lightTheme;
        final theme = accessibility.highContrast
            ? base.copyWith(
                colorScheme: base.colorScheme.copyWith(
                  primary: const Color(0xFF006A50),
                  outline: const Color(0xFF26332E),
                ),
                dividerColor: const Color(0xFF52615B),
              )
            : base;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RutaAmiga',
          theme: theme,
          builder: (context, child) {
            if (!accessibility.largeText || child == null) return child!;
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: const TextScaler.linear(1.15)),
              child: child,
            );
          },
          home:
              initialHome ??
              (Supabase.instance.client.auth.currentSession == null
                  ? const WelcomeScreen()
                  : const PresenceLifecycle(
                      child: PendingProfilePrompt(child: HomeScreen()),
                    )),
        );
      },
    );
  }
}
