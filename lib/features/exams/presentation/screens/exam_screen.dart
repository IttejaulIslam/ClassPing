import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/exam_entry.dart';
import '../providers/exam_providers.dart';
import 'add_edit_exam_screen.dart';

class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    final examsAsync = ref.watch(examProvider);

    return AppBackground(
      bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'Exam Mode'),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 85),
          child: FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddEditExamScreen()),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        body: examsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load exams.\n$e')),
          data: (exams) {
            if (exams.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No exams yet. Tap + to add your first exam, quiz, or lab test.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              );
            }

            final sorted = [...exams]..sort((a, b) => a.examDate.compareTo(b.examDate));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: sorted.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExamCard(exam: sorted[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExamCard extends ConsumerWidget {
  final ExamEntry exam;
  const _ExamCard({required this.exam});

  String _countdownLabel() {
    if (exam.isPast) return 'Completed';
    final d = exam.timeRemaining;
    if (d.inDays >= 1) return 'in ${d.inDays} day${d.inDays == 1 ? '' : 's'}';
    if (d.inHours >= 1) return 'in ${d.inHours}h ${d.inMinutes % 60}m';
    return 'in ${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    final urgent = !exam.isPast && exam.timeRemaining.inDays <= 3;

    return Dismissible(
      key: ValueKey(exam.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        if (exam.id != null) ref.read(examProvider.notifier).deleteExam(exam.id!);
      },
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditExamScreen(existing: exam)),
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          borderColor: urgent ? Colors.redAccent.withValues(alpha: 0.5) : null,
          child: Row(
            children: [
              Checkbox(
                value: exam.isPrepared,
                activeColor: primaryColor,
                onChanged: (_) => ref.read(examProvider.notifier).togglePrepared(exam),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exam.subject,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : Colors.black87,
                              decoration: exam.isPrepared ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exam.examType,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}'
                      '${exam.room.isNotEmpty ? ' \u2022 Room ${exam.room}' : ''}',
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _countdownLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: urgent ? Colors.redAccent : (dark ? Colors.white70 : primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
