import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/dashboard/presentation/screens/main_layout_screen.dart';
import '../../features/exams/presentation/screens/exam_screen.dart';
import '../../features/gpa/presentation/screens/gpa_calculator_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/routine/domain/class_entry.dart';
import '../../features/routine/presentation/screens/add_edit_class_screen.dart';
import '../../features/routine/presentation/screens/import_routine_screen.dart';
import '../../features/routine/presentation/screens/routine_grid_screen.dart';
import '../../features/routine/presentation/screens/routine_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/tasks/domain/task_entry.dart';
import '../../features/tasks/presentation/screens/add_edit_task_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/routine',
                builder: (context, state) => const RoutineScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AddEditClassScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final entry = state.extra as ClassEntry?;
                      return AddEditClassScreen(existing: entry);
                    },
                  ),
                  GoRoute(
                    path: 'grid',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const RoutineGridScreen(),
                  ),
                  GoRoute(
                    path: 'import',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const ImportRoutineScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AddEditTaskScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final task = state.extra as TaskEntry?;
                      return AddEditTaskScreen(existing: task);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/attendance',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/exams',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ExamScreen(),
      ),
      GoRoute(
        path: '/gpa',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GpaCalculatorScreen(),
      ),
    ],
  );
});
