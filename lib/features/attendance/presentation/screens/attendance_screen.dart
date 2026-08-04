import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../routine/presentation/providers/routine_providers.dart';
import '../../domain/attendance_record.dart';
import '../providers/attendance_providers.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    final summaryAsync = ref.watch(attendanceProvider);
    final summary = ref.watch(subjectAttendanceProvider);
    final todaysClasses = ref.watch(todaysClassesProvider);

    return AppBackground(
      bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'Attendance'),
        body: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load attendance.\n$e')),
          data: (_) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (todaysClasses.isNotEmpty) ...[
                Text(
                  "Mark today's classes",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: dark ? Colors.white : primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                ...todaysClasses.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.subject,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: dark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                              onPressed: c.id == null
                                  ? null
                                  : () => ref.read(attendanceProvider.notifier).mark(
                                        classEntryId: c.id!,
                                        subject: c.subject,
                                        date: DateTime.now(),
                                        present: true,
                                      ),
                              child: const Text('Present'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                              onPressed: c.id == null
                                  ? null
                                  : () => ref.read(attendanceProvider.notifier).mark(
                                        classEntryId: c.id!,
                                        subject: c.subject,
                                        date: DateTime.now(),
                                        present: false,
                                      ),
                              child: const Text('Absent'),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
              ],
              Text(
                'Attendance by subject',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: dark ? Colors.white : primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              if (summary.isEmpty)
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No attendance marked yet. Use the buttons above after each class.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
                  ),
                )
              else
                ...summary.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SubjectAttendanceCard(data: s),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectAttendanceCard extends StatelessWidget {
  final SubjectAttendance data;
  const _SubjectAttendanceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final pct = data.percentage;
    final color = pct >= 75 ? Colors.green : (pct >= 60 ? Colors.orange : Colors.redAccent);

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.subject,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: dark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.present} present \u2022 ${data.absent} absent \u2022 ${data.total} total',
            style: TextStyle(fontSize: 11.5, color: dark ? Colors.white54 : Colors.black45),
          ),
          if (pct < 75 && data.total > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Below the typical 75% requirement.',
              style: TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}
