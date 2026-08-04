import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/rounded_field.dart';
import '../../domain/exam_entry.dart';
import '../providers/exam_providers.dart';

class AddEditExamScreen extends ConsumerStatefulWidget {
  final ExamEntry? existing;
  const AddEditExamScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends ConsumerState<AddEditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _roomController;
  late final TextEditingController _syllabusController;

  DateTime _examDate = DateTime.now().add(const Duration(days: 7));
  String _examType = 'Midterm';
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  static const _types = ['Quiz', 'Midterm', 'Final', 'Lab Exam', 'Presentation'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _subjectController = TextEditingController(text: existing?.subject ?? '');
    _roomController = TextEditingController(text: existing?.room ?? '');
    _syllabusController = TextEditingController(text: existing?.syllabus ?? '');
    if (existing != null) {
      _examDate = existing.examDate;
      _examType = existing.examType;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _syllabusController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final exam = ExamEntry(
        id: widget.existing?.id,
        subject: _subjectController.text.trim(),
        examDate: _examDate,
        examType: _examType,
        room: _roomController.text.trim(),
        syllabus: _syllabusController.text.trim(),
        isPrepared: widget.existing?.isPrepared ?? false,
      );

      if (_isEditing) {
        await ref.read(examProvider.notifier).updateExam(exam);
      } else {
        await ref.read(examProvider.notifier).addExam(exam);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save exam: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exam?'),
        content: Text('Remove "${existing!.subject}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(examProvider.notifier).deleteExam(existing!.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: dark ? Colors.white70 : Colors.black54,
    );

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, _isEditing ? 'Edit Exam' : 'Add Exam'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subject', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: fieldDecoration(context, hint: 'e.g. Digital Image Processing'),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject' : null,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Exam Type', style: labelStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) {
                    final selected = _examType == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: selected,
                      onSelected: (_) => setState(() => _examType = t),
                      selectedColor: primaryColor.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: selected ? primaryColor : (dark ? Colors.white70 : Colors.black87),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text('Exam Date', style: labelStyle),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: RoundedField(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.event_outlined, size: 18, color: dark ? Colors.white70 : primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy').format(_examDate),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Room (optional)', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: TextFormField(
                    controller: _roomController,
                    decoration: fieldDecoration(context, hint: 'e.g. Exam Hall 2'),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Syllabus / topics (optional)', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: TextFormField(
                    controller: _syllabusController,
                    maxLines: 3,
                    decoration: fieldDecoration(context, hint: 'Chapters or topics to prepare'),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Save Exam' : 'Add Exam'),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _delete,
                      child: const Text('Delete Exam'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
