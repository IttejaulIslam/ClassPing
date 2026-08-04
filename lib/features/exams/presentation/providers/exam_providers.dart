import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_helper.dart';
import '../../data/exam_repository.dart';
import '../../domain/exam_entry.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(DatabaseHelper.instance);
});

class ExamNotifier extends AsyncNotifier<List<ExamEntry>> {
  @override
  Future<List<ExamEntry>> build() => ref.read(examRepositoryProvider).getAll();

  Future<void> addExam(ExamEntry exam) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(examRepositoryProvider).add(exam);
      return ref.read(examRepositoryProvider).getAll();
    });
  }

  Future<void> updateExam(ExamEntry exam) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(examRepositoryProvider).update(exam);
      return ref.read(examRepositoryProvider).getAll();
    });
  }

  Future<void> deleteExam(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(examRepositoryProvider).delete(id);
      return ref.read(examRepositoryProvider).getAll();
    });
  }

  Future<void> togglePrepared(ExamEntry exam) async {
    await updateExam(exam.copyWith(isPrepared: !exam.isPrepared));
  }
}

final examProvider = AsyncNotifierProvider<ExamNotifier, List<ExamEntry>>(ExamNotifier.new);

/// Upcoming exams only, soonest first \u2014 used for the countdown list.
final upcomingExamsProvider = Provider<List<ExamEntry>>((ref) {
  final exams = ref.watch(examProvider).valueOrNull ?? const <ExamEntry>[];
  final upcoming = exams.where((e) => !e.isPast).toList()
    ..sort((a, b) => a.examDate.compareTo(b.examDate));
  return upcoming;
});
