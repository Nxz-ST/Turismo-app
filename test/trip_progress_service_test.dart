import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turismo_app/features/profile/services/trip_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
    );
  });

  test('persiste y revierte el progreso de un lugar', () async {
    final service = TripProgressService();
    await service.setCompleted('official-42', true);
    expect(await service.completed(), contains('official-42'));

    await service.setCompleted('official-42', false);
    expect(await service.completed(), isNot(contains('official-42')));
  });
}
