import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class MainLayoutScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor:
            dark ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.6),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Routine',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
