import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/services/notification_service.dart';
import '../../../settings/presentation/providers/semester_break_provider.dart';
import '../../data/routine_repository.dart';
import '../../domain/class_entry.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(DatabaseHelper.instance, NotificationService.instance);
});

class RoutineNotifier extends AsyncNotifier<List<ClassEntry>> {
  @override
  Future<List<ClassEntry>> build() async {
    final entries = await ref.read(routineRepositoryProvider).getAll();

    // Pause/resume all reminders based on whether a semester break is
    // currently active (see SemesterBreakNotifier / Settings > Semester).
    final breakRange = ref.read(semesterBreakProvider);
    unawaited(NotificationService.instance.syncWithSemesterBreak(
      entries: entries,
      breakIsActive: breakRange?.isActiveNow ?? false,
    ));

    return entries;
  }

  Future<void> addEntry(ClassEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(routineRepositoryProvider).add(entry);
      return ref.read(routineRepositoryProvider).getAll();
    });
  }

  Future<void> updateEntry(ClassEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(routineRepositoryProvider).update(entry);
      return ref.read(routineRepositoryProvider).getAll();
    });
  }

  Future<void> deleteEntry(ClassEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(routineRepositoryProvider).delete(entry);
      return ref.read(routineRepositoryProvider).getAll();
    });
  }
}

final routineProvider =
    AsyncNotifierProvider<RoutineNotifier, List<ClassEntry>>(RoutineNotifier.new);

/// Today's classes only, sorted by start time — used by the Today/Home tab.
final todaysClassesProvider = Provider<List<ClassEntry>>((ref) {
  final routine = ref.watch(routineProvider).valueOrNull ?? const <ClassEntry>[];
  final today = DateTime.now().weekday % 7; // Mon=1..Sun=7 -> 0=Sun..6=Sat
  final entries = routine.where((e) => e.dayOfWeek == today).toList()
    ..sort((a, b) {
      final aMinutes = a.startHour * 60 + a.startMinute;
      final bMinutes = b.startHour * 60 + b.startMinute;
      return aMinutes.compareTo(bMinutes);
    });
  return entries;
});
