class AttendanceRecord {
  final int? id;
  final int classEntryId;
  final String subject;
  final DateTime date;
  final String status; // 'present' | 'absent'

  const AttendanceRecord({
    this.id,
    required this.classEntryId,
    required this.subject,
    required this.date,
    required this.status,
  });

  bool get isPresent => status == 'present';

  factory AttendanceRecord.fromMap(Map<String, Object?> map) => AttendanceRecord(
        id: map['id'] as int?,
        classEntryId: map['classEntryId'] as int,
        subject: map['subject'] as String,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        status: map['status'] as String? ?? 'present',
      );
}

/// Aggregated attendance for a single subject, used to render the
/// percentage bar on the Attendance screen.
class SubjectAttendance {
  final String subject;
  final int present;
  final int absent;
  const SubjectAttendance({required this.subject, required this.present, required this.absent});

  int get total => present + absent;
  double get percentage => total == 0 ? 0 : (present / total) * 100;
}
