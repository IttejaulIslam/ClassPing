import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await NotificationService.instance.requestPermissions();
    } catch (_) {}
    if (!mounted) return;
    // A real (cancellable) Timer instead of a bare Future.delayed, so if
    // this screen is disposed before the delay elapses (fast back-nav,
    // hot restart, etc.) the pending navigation is cancelled cleanly
    // rather than left dangling.
    _navigationTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/today');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return AppBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              size: 64,
              color: dark ? Colors.white : primaryColor,
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 16),
            Text(
              'ClassPing',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : primaryColor,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Never miss a class',
              style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
