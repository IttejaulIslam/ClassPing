import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

/// Exports every local table (routine, tasks, attendance, exams, grades) to
/// a single JSON file the user can share/save anywhere (Google Drive, email,
/// a USB cable, etc.), and can later re-import on the same or a new device.
///
/// This directly addresses the "no backup, data lost on uninstall" risk —
/// everything in ClassPing lives only in the on-device SQLite file otherwise.
class BackupService {
  BackupService(this._db);
  final DatabaseHelper _db;

  static const _formatVersion = 1;

  /// Builds the backup file and returns its path so the caller can decide
  /// whether to open the share sheet immediately.
  Future<File> exportToFile() async {
    final tables = await _db.exportAllTables();
    final payload = {
      'app': 'ClassPing',
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    };

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/classping_backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }

  /// Exports and immediately opens the OS share sheet (email, Drive, etc.).
  ///
  /// NOTE: share_plus's API has shifted between major versions (older:
  /// `Share.shareXFiles([...])`, newer: `SharePlus.instance.share(...)`).
  /// If this fails to compile against whatever version `flutter pub get`
  /// resolves, check the installed package's README for the current call —
  /// this is the one spot in the whole feature likely to need a one-line fix.
  Future<void> exportAndShare() async {
    final file = await exportToFile();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'ClassPing backup — ${DateTime.now().toString().split(' ').first}',
    );
  }

  /// Reads a previously exported JSON file and restores it, replacing all
  /// current data. Returns a short human-readable summary for a confirmation
  /// dialog / snackbar.
  Future<String> restoreFromFile(File file) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    if (decoded['app'] != 'ClassPing') {
      throw const FormatException('This file was not created by ClassPing.');
    }

    final tablesRaw = decoded['tables'] as Map<String, dynamic>? ?? {};
    final tables = <String, List<Map<String, Object?>>>{};
    for (final entry in tablesRaw.entries) {
      final rows = (entry.value as List<dynamic>)
          .map((r) => Map<String, Object?>.from(r as Map))
          .toList();
      tables[entry.key] = rows;
    }

    await _db.importAllTables(tables);

    final counts = tables.map((k, v) => MapEntry(k, v.length));
    return 'Restored: ${counts['class_entries'] ?? 0} classes, '
        '${counts['tasks'] ?? 0} tasks, '
        '${counts['attendance'] ?? 0} attendance records, '
        '${counts['exams'] ?? 0} exams, '
        '${counts['course_grades'] ?? 0} course grades.';
  }
}
