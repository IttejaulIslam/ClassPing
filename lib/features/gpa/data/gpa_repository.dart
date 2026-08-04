import '../../../core/database/database_helper.dart';
import '../domain/course_grade.dart';

class GpaRepository {
  final DatabaseHelper _db;
  GpaRepository(this._db);

  Future<List<CourseGrade>> getAll() async {
    final rows = await _db.getAllCourseGrades();
    return rows.map(CourseGrade.fromMap).toList();
  }

  Future<void> add(CourseGrade grade) => _db.insertCourseGrade(grade.toMap());

  Future<void> delete(int id) => _db.deleteCourseGrade(id);
}
