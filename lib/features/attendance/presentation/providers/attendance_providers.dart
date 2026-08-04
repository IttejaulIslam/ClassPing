import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_helper.dart';
import '../../data/attendance_repository.dart';
import '../../domain/attendance_record.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(DatabaseHelper.instance);
});

class AttendanceNotifier extends AsyncNotifier<List<AttendanceRecord>> {
  @override
  Future<List<AttendanceRecord>> build() {
    return ref.read(attendanceRepositoryProvider).getAll();
  }

  Future<void> mark({
    required int classEntryId,
    required String subject,
    required DateTime date,
    required bool present,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(attendanceRepositoryProvider).mark(
            classEntryId: classEntryId,
            subject: subject,
            date: date,
            present: present,
          );
      return ref.read(attendanceRepositoryProvider).getAll();
    });
  }
}

final attendanceProvider =
    AsyncNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(AttendanceNotifier.new);

final subjectAttendanceProvider = Provider<List<SubjectAttendance>>((ref) {
  final records = ref.watch(attendanceProvider).valueOrNull ?? const <AttendanceRecord>[];
  return ref.read(attendanceRepositoryProvider).summarize(records);
});
