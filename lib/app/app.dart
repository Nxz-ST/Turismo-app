import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/presence_lifecycle.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RutaAmigaApp extends StatelessWidget {
  const RutaAmigaApp({super.key, this.initialHome});

  final Widget? initialHome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RutaAmiga',
      theme: AppTheme.lightTheme,
      home:
          initialHome ??
          (Supabase.instance.client.auth.currentSession == null
              ? const WelcomeScreen()
              : const PresenceLifecycle(child: HomeScreen())),
    );
  }
}
