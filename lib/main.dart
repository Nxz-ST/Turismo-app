import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/services/app_accessibility_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.validate();

  await Supabase.initialize(
    url: AppEnvironment.supabaseUrl,
    publishableKey: AppEnvironment.supabasePublishableKey,
  );
  await AppAccessibilityService.instance.load();

  runApp(const RutaAmigaApp());
}
