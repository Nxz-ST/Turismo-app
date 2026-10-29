class AppEnvironment {
  AppEnvironment._();

  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void validate() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
      if (apiBaseUrl.isEmpty) 'API_BASE_URL',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Faltan variables de entorno Flutter: ${missing.join(', ')}',
      );
    }
  }
}
