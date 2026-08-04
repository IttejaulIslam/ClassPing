import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routine/presentation/providers/routine_providers.dart';
import 'settings_providers.dart';

const _kBreakStartKey = 'semester_break_start';
const _kBreakEndKey = 'semester_break_end';

class SemesterBreakRange {
  final DateTime start;
  final DateTime end;
  const SemesterBreakRange({required this.start, required this.end});

  bool get isActiveNow {
    final now = DateTime.now();
    return !now.isBefore(start) && !now.isAfter(end);
  }

  /// Whether the given occurrence date falls inside the break — used by
  /// NotificationService to decide whether to skip scheduling a reminder.
  bool covers(DateTime date) => !date.isBefore(start) && !date.isAfter(end);
}

/// A single upcoming/current break range (e.g. semester vacation, Eid
/// holidays). Kept intentionally simple — one range at a time — since a
/// student project rarely needs more than "the next long break".
class SemesterBreakNotifier extends Notifier<SemesterBreakRange?> {
  @override
  SemesterBreakRange? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final startIso = prefs.getString(_kBreakStartKey);
    final endIso = prefs.getString(_kBreakEndKey);
    if (startIso == null || endIso == null) return null;
    final start = DateTime.tryParse(startIso);
    final end = DateTime.tryParse(endIso);
    if (start == null || end == null) return null;
    return SemesterBreakRange(start: start, end: end);
  }

  Future<void> setRange(DateTime start, DateTime end) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kBreakStartKey, start.toIso8601String());
    await prefs.setString(_kBreakEndKey, end.toIso8601String());
    state = SemesterBreakRange(start: start, end: end);
    ref.invalidate(routineProvider); // re-runs the pause/resume sync
  }

  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kBreakStartKey);
    await prefs.remove(_kBreakEndKey);
    state = null;
    ref.invalidate(routineProvider); // reminders resume immediately
  }
}

final semesterBreakProvider =
    NotifierProvider<SemesterBreakNotifier, SemesterBreakRange?>(SemesterBreakNotifier.new);
