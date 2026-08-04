import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/cse_course_catalog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/rounded_field.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/class_entry.dart';
import '../providers/routine_providers.dart';

class AddEditClassScreen extends ConsumerStatefulWidget {
  final ClassEntry? existing;
  const AddEditClassScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditClassScreen> createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends ConsumerState<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _roomController;
  late final TextEditingController _instructorController;

  int _dayOfWeek = DateTime.now().weekday % 7;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  int _reminderMinutes = 10;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _subjectController = TextEditingController(text: existing?.subject ?? '');
    _roomController = TextEditingController(text: existing?.room ?? '');
    _instructorController = TextEditingController(text: existing?.instructor ?? '');

    if (existing != null) {
      _dayOfWeek = existing.dayOfWeek;
      _startTime = TimeOfDay(hour: existing.startHour, minute: existing.startMinute);
      _endTime = TimeOfDay(hour: existing.endHour, minute: existing.endMinute);
      _reminderMinutes = existing.reminderMinutesBefore;
    } else {
      _reminderMinutes = ref.read(defaultReminderProvider);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after the start time.')),
      );
      return;
    }

    final entry = ClassEntry(
      id: widget.existing?.id,
      subject: _subjectController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      room: _roomController.text.trim(),
      instructor: _instructorController.text.trim(),
      reminderMinutesBefore: _reminderMinutes,
    );

    // Conflict check: warn (don't block) if this overlaps another class on
    // the same day, since a student might genuinely have two overlapping
    // options (e.g. a makeup class) and should decide, not be forced.
    final existingEntries = ref.read(routineProvider).valueOrNull ?? const <ClassEntry>[];
    final conflicts = existingEntries.where((e) => entry.overlaps(e)).toList();
    if (conflicts.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Schedule conflict'),
          content: Text(
            'This overlaps with ${conflicts.map((c) => c.subject).join(", ")} '
            'on ${kDays[_dayOfWeek]}. Save anyway?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save Anyway')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await ref.read(routineProvider.notifier).updateEntry(entry);
      } else {
        await ref.read(routineProvider.notifier).addEntry(entry);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save class: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('Remove ${existing.subject} from your routine?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        await ref.read(routineProvider.notifier).deleteEntry(existing);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete class: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
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
        appBar: appBar(context, _isEditing ? 'Edit Class' : 'Add Class'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subject', style: labelStyle),
                const SizedBox(height: 6),
                RawAutocomplete<CatalogCourse>(
                  textEditingController: _subjectController,
                  optionsBuilder: (TextEditingValue value) {
                    final q = value.text.trim().toLowerCase();
                    if (q.isEmpty) return const Iterable<CatalogCourse>.empty();
                    return allCseCourses.where((c) =>
                        c.code.toLowerCase().contains(q) ||
                        c.title.toLowerCase().contains(q)).take(20);
                  },
                  displayStringForOption: (c) => c.title,
                  onSelected: (course) {
                    // Routine subjects display as plain names (e.g. "Digital
                    // Image Processing"), so fill just the title here \u2014
                    // unlike the GPA calculator, which keeps the code too.
                    _subjectController.text = course.title;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return RoundedField(
                      child: TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: fieldDecoration(context, hint: 'e.g. Data Structures'),
                        style: TextStyle(color: dark ? Colors.white : Colors.black87),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter a subject name' : null,
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(14),
                        color: dark ? const Color(0xFF2A0F1D) : Colors.white,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final course = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  course.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: dark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  course.code,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: dark ? Colors.white54 : primaryColor,
                                  ),
                                ),
                                onTap: () => onSelected(course),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text('Day of week', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: DropdownButtonFormField<int>(
                    initialValue: _dayOfWeek,
                    decoration: fieldDecoration(context),
                    dropdownColor: dark ? const Color(0xFF2C2C32) : Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? Colors.white70 : primaryColor),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    items: [
                      for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(kDays[i])),
                    ],
                    onChanged: (v) => setState(() => _dayOfWeek = v ?? _dayOfWeek),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerField(
                        label: 'Starts',
                        time: _startTime,
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePickerField(
                        label: 'Ends',
                        time: _endTime,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Room (optional)', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: TextFormField(
                    controller: _roomController,
                    decoration: fieldDecoration(context, hint: 'e.g. 504'),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Instructor (optional)', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: TextFormField(
                    controller: _instructorController,
                    decoration: fieldDecoration(context, hint: 'e.g. Abir Hassan'),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Remind me before class', style: labelStyle),
                const SizedBox(height: 6),
                RoundedField(
                  child: DropdownButtonFormField<int>(
                    initialValue: _reminderMinutes,
                    decoration: fieldDecoration(context),
                    dropdownColor: dark ? const Color(0xFF2C2C32) : Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? Colors.white70 : primaryColor),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    items: const [0, 5, 10, 15, 20, 30]
                        .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m == 0 ? 'At time of class' : '$m minutes before')))
                        .toList(),
                    onChanged: (v) => setState(() => _reminderMinutes = v ?? _reminderMinutes),
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
                        : Text(_isEditing ? 'Save Changes' : 'Add to Routine'),
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
                      child: const Text('Delete Class'),
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

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimePickerField({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: RoundedField(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: dark ? Colors.white54 : Colors.black45)),
              const SizedBox(height: 4),
              Text(
                time.format(context),
                style: TextStyle(fontWeight: FontWeight.w700, color: dark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
