import '../../../core/database/database_helper.dart';
import '../domain/exam_entry.dart';

class ExamRepository {
  final DatabaseHelper _db;
  ExamRepository(this._db);

  Future<List<ExamEntry>> getAll() async {
    final rows = await _db.getAllExams();
    return rows.map(ExamEntry.fromMap).toList();
  }

  Future<ExamEntry> add(ExamEntry exam) async {
    final id = await _db.insertExam(exam.toMap());
    return exam.copyWith(id: id);
  }

  Future<void> update(ExamEntry exam) => _db.updateExam(exam.toMap());

  Future<void> delete(int id) => _db.deleteExam(id);
}
