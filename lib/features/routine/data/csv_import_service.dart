import 'package:csv/csv.dart';

import '../../../core/utils/time_formatter.dart';
import '../domain/class_entry.dart';

class CsvImportRow {
  final int rowNumber;
  final ClassEntry? entry;
  final String? error;
  const CsvImportRow({required this.rowNumber, this.entry, this.error});
  bool get isValid => entry != null;
}

class CsvImportResult {
  final List<CsvImportRow> rows;
  const CsvImportResult(this.rows);
  List<ClassEntry> get validEntries =>
      rows.where((r) => r.isValid).map((r) => r.entry!).toList();
  int get successCount => validEntries.length;
  int get errorCount => rows.length - successCount;
}

/// Parses a routine CSV with the template header:
/// Subject, Day, Start, End, Room, Instructor
///
/// Times accept common formats like "9:00 AM", "09:00", "9:00am".
/// Any row that fails to parse is reported with a reason rather than
/// silently dropped, so the user can see exactly what to fix.
class CsvImportService {
  static const templateHeader = 'Subject,Day,Start,End,Room,Instructor';
  static const templateSample =
      'Data Structures,Monday,10:00 AM,11:15 AM,504,Abir Hassan\n'
      'Digital Image Processing,Wednesday,9:00 AM,10:15 AM,302,';

  static String templateCsv() => '$templateHeader\n$templateSample\n';

  CsvImportResult parse(String csvContent) {
    final table = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(csvContent, fieldDelimiter: ',');

    if (table.isEmpty) return const CsvImportResult([]);

    // Skip a header row if the first cell looks like "Subject" (case-insensitive).
    final startIndex =
        table.first.isNotEmpty && table.first.first.toString().toLowerCase().contains('subject') ? 1 : 0;

    final rows = <CsvImportRow>[];
    for (var i = startIndex; i < table.length; i++) {
      final raw = table[i];
      final rowNumber = i + 1;
      if (raw.isEmpty || raw.every((c) => c.toString().trim().isEmpty)) continue;

      try {
        final cols = raw.map((c) => c.toString().trim()).toList();
        if (cols.length < 4) {
          rows.add(CsvImportRow(
            rowNumber: rowNumber,
            error: 'Expected at least 4 columns (Subject, Day, Start, End), found ${cols.length}',
          ));
          continue;
        }

        final subject = cols[0];
        final dayText = cols[1];
        final startText = cols[2];
        final endText = cols[3];
        final room = cols.length > 4 ? cols[4] : '';
        final instructor = cols.length > 5 ? cols[5] : '';

        if (subject.isEmpty) {
          rows.add(CsvImportRow(rowNumber: rowNumber, error: 'Subject is empty'));
          continue;
        }

        final dayOfWeek = _parseDay(dayText);
        if (dayOfWeek == null) {
          rows.add(CsvImportRow(
            rowNumber: rowNumber,
            error: 'Could not recognize day "$dayText" (use Sunday..Saturday)',
          ));
          continue;
        }

        final start = _parseTime(startText);
        final end = _parseTime(endText);
        if (start == null || end == null) {
          rows.add(CsvImportRow(
            rowNumber: rowNumber,
            error: 'Could not parse time "$startText" / "$endText" (try "9:00 AM")',
          ));
          continue;
        }
        if (end.$1 * 60 + end.$2 <= start.$1 * 60 + start.$2) {
          rows.add(CsvImportRow(rowNumber: rowNumber, error: 'End time must be after start time'));
          continue;
        }

        rows.add(CsvImportRow(
          rowNumber: rowNumber,
          entry: ClassEntry(
            subject: subject,
            dayOfWeek: dayOfWeek,
            startHour: start.$1,
            startMinute: start.$2,
            endHour: end.$1,
            endMinute: end.$2,
            room: room,
            instructor: instructor,
          ),
        ));
      } catch (e) {
        rows.add(CsvImportRow(rowNumber: rowNumber, error: 'Unexpected error: $e'));
      }
    }

    return CsvImportResult(rows);
  }

  int? _parseDay(String text) {
    final t = text.trim().toLowerCase();
    for (var i = 0; i < kDays.length; i++) {
      if (kDays[i].toLowerCase() == t || kDays[i].toLowerCase().startsWith(t.substring(0, t.length.clamp(0, 3)))) {
        // exact match takes priority; startsWith only for 3-letter abbreviations like "Mon"
        if (kDays[i].toLowerCase() == t || (t.length == 3 && kDays[i].toLowerCase().startsWith(t))) {
          return i;
        }
      }
    }
    return null;
  }

  /// Returns (hour24, minute) or null if unparseable.
  (int, int)? _parseTime(String text) {
    final t = text.trim().toLowerCase().replaceAll(' ', '');
    final match = RegExp(r'^(\d{1,2}):(\d{2})(am|pm)?$').firstMatch(t);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final period = match.group(3);
    if (hour == null || minute == null) return null;
    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }
}
