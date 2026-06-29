import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { light, dark, system }

class ThemeNotifier extends StateNotifier<ThemeModeOption> {
  ThemeNotifier() : super(ThemeModeOption.dark) {
    _loadThemeMode();
  }

  static const String _themeKey = 'theme_mode';

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme == null) {
        state = ThemeModeOption.dark;
        await prefs.setString(_themeKey, ThemeModeOption.dark.name);
        return;
      }
      final mode = ThemeModeOption.values.firstWhere(
        (m) => m.name == savedTheme,
        orElse: () => ThemeModeOption.dark,
      );
      state = mode;
    } catch (e) {
      state = ThemeModeOption.dark;
      await prefs.setString(_themeKey, ThemeModeOption.dark.name);
    }
  }
  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }
}
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeModeOption>(
  (ref) => ThemeNotifier(),
);
