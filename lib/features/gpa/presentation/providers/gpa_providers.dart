import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_helper.dart';
import '../../data/gpa_repository.dart';
import '../../domain/course_grade.dart';

final gpaRepositoryProvider = Provider<GpaRepository>((ref) {
  return GpaRepository(DatabaseHelper.instance);
});

class GpaNotifier extends AsyncNotifier<List<CourseGrade>> {
  @override
  Future<List<CourseGrade>> build() => ref.read(gpaRepositoryProvider).getAll();

  Future<void> addCourse(CourseGrade grade) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(gpaRepositoryProvider).add(grade);
      return ref.read(gpaRepositoryProvider).getAll();
    });
  }

  Future<void> deleteCourse(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(gpaRepositoryProvider).delete(id);
      return ref.read(gpaRepositoryProvider).getAll();
    });
  }
}

final gpaProvider = AsyncNotifierProvider<GpaNotifier, List<CourseGrade>>(GpaNotifier.new);

final overallCgpaProvider = Provider<double>((ref) {
  final courses = ref.watch(gpaProvider).valueOrNull ?? const <CourseGrade>[];
  return GpaCalculator.computeGpa(courses);
});

final semesterBreakdownProvider = Provider<List<({String semester, double gpa, double cgpa})>>((ref) {
  final courses = ref.watch(gpaProvider).valueOrNull ?? const <CourseGrade>[];
  return GpaCalculator.computeSemesterBreakdown(courses);
});
