import '../../../core/utils/time_formatter.dart';

/// A single recurring weekly class slot.
///
/// [dayOfWeek] follows the same convention as [kDays]: 0 = Sunday ... 6 =
/// Saturday (so it lines up directly with `DateTime.now().weekday % 7`).
class ClassEntry {
  final int? id;
  final String subject;
  final int dayOfWeek;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String room;
  final String instructor;
  final int reminderMinutesBefore;

  const ClassEntry({
    this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.room = '',
    this.instructor = '',
    this.reminderMinutesBefore = 10,
  });

  String get dayName => kDays[dayOfWeek];

  String get startTimeLabel => format12Hour(
        '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}',
      );

  String get endTimeLabel => format12Hour(
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
      );

  /// Stable id derived from day + start time so the same weekly slot always
  /// maps to the same scheduled notification (no duplicates on reschedule).
  int get notificationId => (dayOfWeek * 10000) + (startHour * 100) + startMinute;

  int get _startMinutes => startHour * 60 + startMinute;
  int get _endMinutes => endHour * 60 + endMinute;

  /// True if [other] falls on the same day and its time range overlaps this
  /// entry's — used to warn about double-booked classes before saving.
  bool overlaps(ClassEntry other) {
    if (other.dayOfWeek != dayOfWeek) return false;
    if (other.id != null && other.id == id) return false; // editing itself
    return _startMinutes < other._endMinutes && other._startMinutes < _endMinutes;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'subject': subject,
        'dayOfWeek': dayOfWeek,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'room': room,
        'instructor': instructor,
        'reminderMinutesBefore': reminderMinutesBefore,
      };

  factory ClassEntry.fromMap(Map<String, Object?> map) => ClassEntry(
        id: map['id'] as int?,
        subject: map['subject'] as String,
        dayOfWeek: map['dayOfWeek'] as int,
        startHour: map['startHour'] as int,
        startMinute: map['startMinute'] as int,
        endHour: map['endHour'] as int,
        endMinute: map['endMinute'] as int,
        room: (map['room'] as String?) ?? '',
        instructor: (map['instructor'] as String?) ?? '',
        reminderMinutesBefore: (map['reminderMinutesBefore'] as int?) ?? 10,
      );

  ClassEntry copyWith({
    int? id,
    String? subject,
    int? dayOfWeek,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? room,
    String? instructor,
    int? reminderMinutesBefore,
  }) {
    return ClassEntry(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }
}
