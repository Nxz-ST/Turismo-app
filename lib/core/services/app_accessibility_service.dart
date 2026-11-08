import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAccessibilityService extends ChangeNotifier {
  AppAccessibilityService._();

  static final instance = AppAccessibilityService._();
  static const _largeTextKey = 'rutaamiga_accessibility_large_text_v1';
  static const _highContrastKey = 'rutaamiga_accessibility_high_contrast_v1';

  bool largeText = false;
  bool highContrast = false;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    largeText = preferences.getBool(_largeTextKey) ?? false;
    highContrast = preferences.getBool(_highContrastKey) ?? false;
  }

  Future<void> setLargeText(bool value) async {
    if (largeText == value) return;
    largeText = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_largeTextKey, value);
  }

  Future<void> setHighContrast(bool value) async {
    if (highContrast == value) return;
    highContrast = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_highContrastKey, value);
  }
}
