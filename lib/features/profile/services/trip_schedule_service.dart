import 'package:shared_preferences/shared_preferences.dart';

class TripScheduleService {
  static const _key = 'rutaamiga_trip_departure';

  Future<DateTime?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> save(DateTime value) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      value.toIso8601String(),
    );
  }

  Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
