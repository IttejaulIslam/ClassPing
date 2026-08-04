import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDefaultReminderKey = 'default_reminder_minutes';
const _kThemeModeKey = 'theme_mode';

/// Overridden in main() with the real SharedPreferences instance before
/// runApp() — see the ProviderScope overrides list.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

class DefaultReminderNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getInt(_kDefaultReminderKey) ?? 10;
  }

  Future<void> update(int minutes) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_kDefaultReminderKey, minutes);
    state = minutes;
  }
}

final defaultReminderProvider =
    NotifierProvider<DefaultReminderNotifier, int>(DefaultReminderNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_kThemeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> update(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kThemeModeKey, mode.name);
    state = mode;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
