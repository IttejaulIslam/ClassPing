import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/rounded_field.dart';
import '../../../routine/presentation/providers/routine_providers.dart';
import '../../domain/task_entry.dart';
import '../providers/tasks_providers.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskEntry? existing;
  const AddEditTaskScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _notesController;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  String _priority = 'Medium';
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _subjectController = TextEditingController(text: existing?.subject ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');

    if (existing != null) {
      _dueDate = existing.dueDate;
      _dueTime = TimeOfDay(hour: existing.dueDate.hour, minute: existing.dueDate.minute);
      _priority = existing.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final combinedDueDate = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      final task = TaskEntry(
        id: widget.existing?.id,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim().isEmpty ? 'General' : _subjectController.text.trim(),
        dueDate: combinedDueDate,
        priority: _priority,
        isCompleted: widget.existing?.isCompleted ?? false,
        notes: _notesController.text.trim(),
      );

      if (_isEditing) {
        await ref.read(tasksProvider.notifier).updateTask(task);
      } else {
        await ref.read(tasksProvider.notifier).addTask(task);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save task: $e')),
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
        title: const Text('Delete Task?'),
        content: Text('Remove "${existing!.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        await ref.read(tasksProvider.notifier).deleteTask(existing!.id!);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete task: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final routineAsync = ref.watch(routineProvider);
    final routineSubjects = routineAsync.valueOrNull?.map((e) => e.subject).toSet().toList() ?? [];

    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: dark ? Colors.white70 : Colors.black54,
    );

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, _isEditing ? 'Edit Task' : 'Add Task'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task Title', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: TextFormField(
                    controller: _titleController,
                    decoration: fieldDecoration(context, hint: 'e.g. Complete Lab Report 3'),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a task title' : null,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Subject (optional)', style: labelStyle),
                const SizedBox(height: 6),
                if (routineSubjects.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: routineSubjects.map((sub) {
                      final isSelected = _subjectController.text == sub;
                      return ChoiceChip(
                        label: Text(sub),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _subjectController.text = selected ? sub : '';
                          });
                        },
                        selectedColor: primaryColor.withValues(alpha: 0.25),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : (dark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                RoundedField(
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: fieldDecoration(context, hint: 'e.g. Data Structures'),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Due Date & Time', style: labelStyle),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: RoundedField(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month_outlined,
                                    size: 18, color: dark ? Colors.white70 : primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMM dd, yyyy').format(_dueDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: dark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: RoundedField(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 18, color: dark ? Colors.white70 : primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dueTime.format(context),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: dark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Priority Level', style: labelStyle),
                const SizedBox(height: 8),
                Row(
                  children: ['Low', 'Medium', 'High'].map((p) {
                    final isSelected = _priority == p;
                    Color pColor;
                    if (p == 'High') {
                      pColor = Colors.redAccent;
                    } else if (p == 'Medium') {
                      pColor = Colors.orangeAccent;
                    } else {
                      pColor = Colors.blueAccent;
                    }
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => _priority = p),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? pColor.withValues(alpha: 0.25)
                                  : (dark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03)),
                              border: Border.all(
                                color: isSelected ? pColor : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? pColor
                                      : (dark ? Colors.white70 : Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text('Notes (optional)', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: fieldDecoration(context, hint: 'Add details or requirements...'),
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
                        : Text(_isEditing ? 'Save Task' : 'Create Task'),
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
                      child: const Text('Delete Task'),
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
