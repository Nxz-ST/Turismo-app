import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();
  static const _tripReminderId = 4101;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Lima'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<void> scheduleTripReminder(
    DateTime departure,
    String firstPlace,
  ) async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin.cancel(id: _tripReminderId);
    final now = DateTime.now();
    var reminder = departure.subtract(const Duration(hours: 24));
    if (!reminder.isAfter(now)) {
      reminder = departure.subtract(const Duration(hours: 1));
    }
    if (!reminder.isAfter(now)) {
      reminder = now.add(const Duration(seconds: 10));
    }
    if (!departure.isAfter(now)) {
      return;
    }
    await _plugin.zonedSchedule(
      id: _tripReminderId,
      title: 'Tu viaje está cerca',
      body: 'Revisa el clima, tu ruta y lo necesario para visitar $firstPlace.',
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_planning',
          'Planificación de viajes',
          channelDescription:
              'Recordatorios de las salidas programadas en RutaAmiga',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
