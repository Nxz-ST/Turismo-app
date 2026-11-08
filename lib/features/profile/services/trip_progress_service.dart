import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripProgressService {
  String get _key =>
      'rutaamiga_trip_completed_v1_${Supabase.instance.client.auth.currentUser?.id ?? 'guest'}';

  Future<Set<String>> completed() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? const []).toSet();
  }

  Future<void> setCompleted(String libraryKey, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    final items = (preferences.getStringList(_key) ?? const []).toSet();
    value ? items.add(libraryKey) : items.remove(libraryKey);
    await preferences.setStringList(_key, items.toList());
  }
}
