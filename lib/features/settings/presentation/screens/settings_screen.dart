import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/settings_providers.dart';
import '../providers/semester_break_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
  }

  Future<void> _refreshPermissionStatus() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _requestPermissions() async {
    await NotificationService.instance.requestPermissions();
    _refreshPermissionStatus();
  }

  bool _backupBusy = false;

  Future<void> _exportBackup() async {
    setState(() => _backupBusy = true);
    try {
      await BackupService(DatabaseHelper.instance).exportAndShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This replaces all current classes, tasks, attendance, exams, and '
          'grades with the contents of the selected file. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _backupBusy = true);
    try {
      final summary = await BackupService(DatabaseHelper.instance).restoreFromFile(File(path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(summary)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final defaultReminder = ref.watch(defaultReminderProvider);
    final themeMode = ref.watch(themeModeProvider);

    return AppBackground(
      bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'Settings'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _SectionLabel('Notifications'),
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _notificationsEnabled == true ? Icons.notifications_active : Icons.notifications_off,
                      color: _notificationsEnabled == true ? Colors.green : Colors.orange,
                    ),
                    title: const Text('Reminder permissions'),
                    subtitle: Text(
                      _notificationsEnabled == true
                          ? 'Enabled \u2014 reminders will fire on time'
                          : 'Not fully enabled yet \u2014 tap to fix',
                    ),
                    onTap: _requestPermissions,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Default reminder time'),
                    subtitle: Text('$defaultReminder minutes before a new class'),
                    trailing: DropdownButton<int>(
                      value: defaultReminder,
                      underline: const SizedBox.shrink(),
                      items: const [0, 5, 10, 15, 20, 30]
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m == 0 ? 'At time of class' : '$m min before')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) ref.read(defaultReminderProvider.notifier).update(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Appearance'),
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System default'),
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (m) => ref.read(themeModeProvider.notifier).update(m!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (m) => ref.read(themeModeProvider.notifier).update(m!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (m) => ref.read(themeModeProvider.notifier).update(m!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Data & Backup'),
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.upload_file_outlined, color: dark ? Colors.white70 : primaryColor),
                    title: const Text('Export backup'),
                    subtitle: const Text('Save everything to a JSON file you can share or store'),
                    trailing: _backupBusy
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                    onTap: _backupBusy ? null : _exportBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.download_outlined, color: dark ? Colors.white70 : primaryColor),
                    title: const Text('Restore from backup'),
                    subtitle: const Text('Replace current data with a previously exported file'),
                    onTap: _backupBusy ? null : _importBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.table_chart_outlined, color: dark ? Colors.white70 : primaryColor),
                    title: const Text('Import routine from CSV'),
                    subtitle: const Text('Bulk-add classes from a spreadsheet'),
                    onTap: () => context.push('/routine/import'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Semester'),
            const _SemesterBreakCard(),
            const SizedBox(height: 20),
            _SectionLabel('Tools'),
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.grid_view_rounded, color: dark ? Colors.white70 : primaryColor),
                    title: const Text('Weekly timetable grid'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/routine/grid'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.fact_check_outlined, color: dark ? Colors.white70 : primaryColor),
                    title: const Text('Attendance tracker'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/attendance'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.edit_calendar_outlined, color: dark ? Colors.white70 : primaryColor),
                    title: const Text('Exam mode'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/exams'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.calculate_outlined, color: dark ? Colors.white70 : primaryColor),
                    title: const Text('GPA / CGPA calculator'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/gpa'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('About'),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ClassPing',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: dark ? Colors.white : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A weekly class routine reminder app. Works fully offline \u2014 '
                    'your routine and reminders live entirely on this device.',
                    style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the student mark a date range (semester break, holidays) during
/// which class reminders are paused, then automatically resumed once the
/// range has passed. Addresses reminders otherwise firing all through
/// vacation since notifications repeat weekly forever once scheduled.
class _SemesterBreakCard extends ConsumerWidget {
  const _SemesterBreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    final breakRange = ref.watch(semesterBreakProvider);
    final isActive = breakRange != null && breakRange.isActiveNow;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: isActive ? Colors.orange : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Reminders paused (on break)' : 'Reminders active',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            breakRange == null
                ? 'No break set \u2014 reminders fire every week as usual.'
                : '${_fmt(breakRange.start)} \u2013 ${_fmt(breakRange.end)}',
            style: TextStyle(fontSize: 12.5, color: dark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickRange(context, ref),
                  child: Text(breakRange == null ? 'Set break dates' : 'Change dates'),
                ),
              ),
              if (breakRange != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () => ref.read(semesterBreakProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      await ref.read(semesterBreakProvider.notifier).setRange(picked.start, picked.end);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Break saved. Reminders inside this range will be skipped.'),
          ),
        );
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: dark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}
