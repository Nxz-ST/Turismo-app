import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.validate();

  await Supabase.initialize(
    url: AppEnvironment.supabaseUrl,
    publishableKey: AppEnvironment.supabasePublishableKey,
  );

  runApp(const RutaAmigaApp());
}
