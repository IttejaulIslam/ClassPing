class ExamEntry {
  final int? id;
  final String subject;
  final DateTime examDate;
  final String examType; // 'Quiz', 'Midterm', 'Final', 'Lab Exam'
  final String room;
  final String syllabus;
  final bool isPrepared;

  const ExamEntry({
    this.id,
    required this.subject,
    required this.examDate,
    this.examType = 'Midterm',
    this.room = '',
    this.syllabus = '',
    this.isPrepared = false,
  });

  Duration get timeRemaining => examDate.difference(DateTime.now());
  bool get isPast => examDate.isBefore(DateTime.now());

  ExamEntry copyWith({
    int? id,
    String? subject,
    DateTime? examDate,
    String? examType,
    String? room,
    String? syllabus,
    bool? isPrepared,
  }) {
    return ExamEntry(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      examType: examType ?? this.examType,
      room: room ?? this.room,
      syllabus: syllabus ?? this.syllabus,
      isPrepared: isPrepared ?? this.isPrepared,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'subject': subject,
        'examDate': examDate.toIso8601String(),
        'examType': examType,
        'room': room,
        'syllabus': syllabus,
        'isPrepared': isPrepared ? 1 : 0,
      };

  factory ExamEntry.fromMap(Map<String, Object?> map) => ExamEntry(
        id: map['id'] as int?,
        subject: map['subject'] as String,
        examDate: DateTime.tryParse(map['examDate'] as String? ?? '') ?? DateTime.now(),
        examType: map['examType'] as String? ?? 'Midterm',
        room: (map['room'] as String?) ?? '',
        syllabus: (map['syllabus'] as String?) ?? '',
        isPrepared: (map['isPrepared'] as int? ?? 0) == 1,
      );
}
