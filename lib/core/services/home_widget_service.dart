import 'package:home_widget/home_widget.dart';

import '../../features/routine/domain/class_entry.dart';
import '../../features/tasks/domain/task_entry.dart';

/// Pushes "next class" + "pending task count" data to a native Android
/// home-screen widget via the `home_widget` package.
///
/// IMPORTANT \u2014 this is the Flutter (Dart) half only. A working home-screen
/// widget also needs native Android files that this environment cannot
/// build/test (no Android SDK here):
///   1. android/app/src/main/res/layout/classping_widget.xml \u2014 the widget's UI
///   2. android/app/src/main/res/xml/classping_widget_info.xml \u2014 widget metadata
///      (size, update period, initial layout)
///   3. android/app/src/main/kotlin/.../ClassPingWidgetProvider.kt \u2014 an
///      AppWidgetProvider that reads the data this service saves and renders it
///   4. A `<receiver>` entry for that provider in AndroidManifest.xml
///
/// See the `home_widget` package's own example app (in its pub.dev repo) for
/// a complete, known-working version of files 1\u20134 \u2014 copy its structure and
/// swap in ClassPing's colors/strings rather than writing them from scratch,
/// since getting Android widget XML exactly right needs testing on a device/
/// emulator, which isn't available in this environment.
class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  static const _kNextClassTitleKey = 'next_class_title';
  static const _kNextClassTimeKey = 'next_class_time';
  static const _kPendingTasksKey = 'pending_tasks_count';

  /// Call this whenever the routine or task list changes (e.g. from
  /// RoutineNotifier/TasksNotifier) so the widget stays in sync.
  Future<void> update({
    required ClassEntry? nextClass,
    required List<TaskEntry> pendingTasks,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        _kNextClassTitleKey,
        nextClass?.subject ?? 'No more classes today',
      );
      await HomeWidget.saveWidgetData<String>(
        _kNextClassTimeKey,
        nextClass == null ? '' : '${nextClass.startTimeLabel} \u2022 ${nextClass.room}',
      );
      await HomeWidget.saveWidgetData<int>(
        _kPendingTasksKey,
        pendingTasks.where((t) => !t.isCompleted).length,
      );
      // Name must match the AppWidgetProvider class registered natively
      // (see ClassPingWidgetProvider.kt referenced above).
      await HomeWidget.updateWidget(
        name: 'ClassPingWidgetProvider',
        androidName: 'ClassPingWidgetProvider',
      );
    } catch (_) {
      // Widget not installed / native side not wired up yet \u2014 fail silently
      // so this never breaks the main app.
    }
  }
}
