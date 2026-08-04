// Smoke test: confirms the app boots and renders the splash screen
// without throwing.
//
// This deliberately stays on the splash screen rather than navigating
// into Today, since Today mounts a Timer.periodic UI clock that runs
// forever by design (see HomeScreen) — a plain widget test has no clean
// way to "finish" a genuinely-infinite timer, so pumpAndSettle() times
// out and manual pump()+dispose() sequencing is fragile. Splash's own
// auto-navigate delay is a real (cancellable) Timer that gets cancelled
// in SplashScreenState.dispose(), so simply letting flutter_test tear
// down the tree here is enough — no pending-timer leak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:classping/main.dart';
import 'package:classping/features/settings/presentation/providers/settings_providers.dart';

void main() {
  testWidgets('App boots and renders the splash screen without throwing',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ClassPingApp(),
      ),
    );

    // Let the splash screen's entrance animations finish, but stay well
    // under its 1.4s auto-navigate delay so HomeScreen never mounts.
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
  });
}
