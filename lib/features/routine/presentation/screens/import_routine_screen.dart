import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../data/csv_import_service.dart';
import '../providers/routine_providers.dart';

class ImportRoutineScreen extends ConsumerStatefulWidget {
  const ImportRoutineScreen({super.key});

  @override
  ConsumerState<ImportRoutineScreen> createState() => _ImportRoutineScreenState();
}

class _ImportRoutineScreenState extends ConsumerState<ImportRoutineScreen> {
  CsvImportResult? _result;
  String? _fileName;
  bool _busy = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final content = await File(path).readAsString();
      final parsed = CsvImportService().parse(content);
      setState(() {
        _result = parsed;
        _fileName = result!.files.single.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmImport() async {
    final result = _result;
    if (result == null || result.validEntries.isEmpty) return;

    setState(() => _busy = true);
    try {
      for (final entry in result.validEntries) {
        await ref.read(routineProvider.notifier).addEntry(entry);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${result.successCount} classes.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'Import Routine'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSV format',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Columns: Subject, Day, Start, End, Room, Instructor\n'
                      'Room and Instructor are optional. Times accept "9:00 AM" '
                      'or "09:00" style formats.',
                      style: TextStyle(fontSize: 12.5, color: dark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: CsvImportService.templateCsv()));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Template CSV copied to clipboard')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('Copy template'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _pickFile,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(_fileName == null ? 'Choose CSV file' : 'Change file ($_fileName)'),
                ),
              ),
              if (_busy) const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              if (_result != null) ...[
                const SizedBox(height: 20),
                Text(
                  '${_result!.successCount} ready to import'
                  '${_result!.errorCount > 0 ? " \u2022 ${_result!.errorCount} rows have errors" : ""}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _result!.errorCount > 0 ? Colors.orange : (dark ? Colors.white : primaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                ..._result!.rows.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        borderColor: row.isValid ? null : Colors.redAccent.withValues(alpha: 0.5),
                        child: Row(
                          children: [
                            Icon(
                              row.isValid ? Icons.check_circle : Icons.error_outline,
                              size: 18,
                              color: row.isValid ? Colors.green : Colors.redAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                row.isValid
                                    ? '${row.entry!.subject} \u2014 ${row.entry!.dayName} '
                                        '${row.entry!.startTimeLabel}-${row.entry!.endTimeLabel}'
                                    : 'Row ${row.rowNumber}: ${row.error}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: row.isValid
                                      ? (dark ? Colors.white : Colors.black87)
                                      : Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
                if (_result!.successCount > 0)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _confirmImport,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Import ${_result!.successCount} Classes'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
