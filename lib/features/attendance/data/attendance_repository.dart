import '../../../core/database/database_helper.dart';
import '../domain/attendance_record.dart';

class AttendanceRepository {
  final DatabaseHelper _db;
  AttendanceRepository(this._db);

  Future<void> mark({
    required int classEntryId,
    required String subject,
    required DateTime date,
    required bool present,
  }) {
    return _db.markAttendance(
      classEntryId: classEntryId,
      subject: subject,
      date: date,
      status: present ? 'present' : 'absent',
    );
  }

  Future<List<AttendanceRecord>> getAll() async {
    final rows = await _db.getAllAttendance();
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  Future<void> deleteRecord(int id) => _db.deleteAttendanceRecord(id);

  /// Groups every record by subject and computes present/absent counts.
  List<SubjectAttendance> summarize(List<AttendanceRecord> records) {
    final bySubject = <String, List<AttendanceRecord>>{};
    for (final r in records) {
      bySubject.putIfAbsent(r.subject, () => []).add(r);
    }
    return bySubject.entries.map((e) {
      final present = e.value.where((r) => r.isPresent).length;
      final absent = e.value.length - present;
      return SubjectAttendance(subject: e.key, present: present, absent: absent);
    }).toList()
      ..sort((a, b) => a.subject.compareTo(b.subject));
  }
}
