import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart' as theme;
import 'features/settings/presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local notifications are initialized once, up front, fully offline.
  await NotificationService.instance.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ClassPingApp(),
    ),
  );
}

class ClassPingApp extends ConsumerWidget {
  const ClassPingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    final lightScheme = ColorScheme.fromSeed(
      seedColor: theme.primaryColor,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: theme.primaryColor,
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'ClassPing',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      routerConfig: router,
    );
  }
}
