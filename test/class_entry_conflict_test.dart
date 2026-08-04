import 'package:flutter_test/flutter_test.dart';
import 'package:classping/features/routine/domain/class_entry.dart';

ClassEntry _entry({
  int? id,
  String subject = 'Test',
  int day = 1,
  int startH = 10,
  int startM = 0,
  int endH = 11,
  int endM = 0,
}) {
  return ClassEntry(
    id: id,
    subject: subject,
    dayOfWeek: day,
    startHour: startH,
    startMinute: startM,
    endHour: endH,
    endMinute: endM,
  );
}

void main() {
  group('ClassEntry.overlaps', () {
    test('detects a direct overlap on the same day', () {
      final a = _entry(startH: 10, startM: 0, endH: 11, endM: 0);
      final b = _entry(startH: 10, startM: 30, endH: 11, endM: 30);
      expect(a.overlaps(b), isTrue);
      expect(b.overlaps(a), isTrue);
    });

    test('does not flag back-to-back classes as overlapping', () {
      final a = _entry(startH: 10, startM: 0, endH: 11, endM: 0);
      final b = _entry(startH: 11, startM: 0, endH: 12, endM: 0);
      expect(a.overlaps(b), isFalse);
    });

    test('does not flag classes on different days', () {
      final a = _entry(day: 1, startH: 10, endH: 11);
      final b = _entry(day: 2, startH: 10, endH: 11);
      expect(a.overlaps(b), isFalse);
    });

    test('does not flag an entry against itself when editing', () {
      final a = _entry(id: 5, startH: 10, endH: 11);
      final sameEntryEdited = _entry(id: 5, startH: 10, startM: 15, endH: 11);
      expect(a.overlaps(sameEntryEdited), isFalse);
    });

    test('detects one class fully containing another', () {
      final a = _entry(startH: 9, endH: 12);
      final b = _entry(startH: 10, endH: 11);
      expect(a.overlaps(b), isTrue);
    });
  });
}
