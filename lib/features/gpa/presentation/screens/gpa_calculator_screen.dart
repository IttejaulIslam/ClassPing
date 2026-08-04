import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/cse_course_catalog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/rounded_field.dart';
import '../../domain/course_grade.dart';
import '../providers/gpa_providers.dart';

class GpaCalculatorScreen extends ConsumerStatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  ConsumerState<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends ConsumerState<GpaCalculatorScreen> {
  final _courseController = TextEditingController();
  final _semesterController = TextEditingController(text: 'Semester 1');
  final _creditController = TextEditingController(text: '3');
  String _letter = 'A';

  static const _letters = ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'];

  @override
  void dispose() {
    _courseController.dispose();
    _semesterController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  Future<void> _addCourse() async {
    final credits = double.tryParse(_creditController.text.trim());
    if (_courseController.text.trim().isEmpty || credits == null || credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a course name and a valid credit hour value.')),
      );
      return;
    }

    await ref.read(gpaProvider.notifier).addCourse(CourseGrade(
          courseName: _courseController.text.trim(),
          semesterLabel: _semesterController.text.trim().isEmpty
              ? 'Semester 1'
              : _semesterController.text.trim(),
          creditHours: credits,
          gradePoint: letterToGradePoint(_letter),
        ));

    _courseController.clear();
    _creditController.text = '3';
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final coursesAsync = ref.watch(gpaProvider);
    final cgpa = ref.watch(overallCgpaProvider);
    final breakdown = ref.watch(semesterBreakdownProvider);

    return AppBackground(
      bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'GPA / CGPA Calculator'),
        body: coursesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load courses.\n$e')),
          data: (courses) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      'Overall CGPA',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cgpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : primaryColor,
                      ),
                    ),
                    Text(
                      '${courses.length} course${courses.length == 1 ? '' : 's'} entered',
                      style: TextStyle(fontSize: 11.5, color: dark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (breakdown.length > 1) ...[
                Text(
                  'By semester',
                  style: TextStyle(fontWeight: FontWeight.w700, color: dark ? Colors.white : primaryColor),
                ),
                const SizedBox(height: 8),
                ...breakdown.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(b.semester,
                                  style: TextStyle(fontWeight: FontWeight.w600, color: dark ? Colors.white : Colors.black87)),
                            ),
                            Text('GPA ${b.gpa.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : Colors.black54)),
                            const SizedBox(width: 12),
                            Text('CGPA ${b.cgpa.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor)),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
              ],
              Text(
                'Add a course',
                style: TextStyle(fontWeight: FontWeight.w700, color: dark ? Colors.white : primaryColor),
              ),
              const SizedBox(height: 10),
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    RawAutocomplete<CatalogCourse>(
                      textEditingController: _courseController,
                      optionsBuilder: (TextEditingValue value) {
                        final q = value.text.trim().toLowerCase();
                        if (q.isEmpty) return const Iterable<CatalogCourse>.empty();
                        return allCseCourses.where((c) =>
                            c.code.toLowerCase().contains(q) ||
                            c.title.toLowerCase().contains(q)).take(20);
                      },
                      displayStringForOption: (c) => c.displayLabel,
                      onSelected: (course) {
                        _courseController.text = course.displayLabel;
                        final credit = course.credit;
                        _creditController.text = credit == credit.roundToDouble()
                            ? credit.toInt().toString()
                            : credit.toString();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return RoundedField(
                          child: TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: fieldDecoration(
                              context,
                              hint: 'Course name or code (e.g. CSE225)',
                            ),
                            style: TextStyle(color: dark ? Colors.white : Colors.black87),
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
                                      course.code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: dark ? Colors.white : primaryColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      course.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: dark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${course.credit} cr',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: dark ? Colors.white54 : Colors.black45,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: RoundedField(
                            child: TextFormField(
                              controller: _semesterController,
                              decoration: fieldDecoration(context, hint: 'Semester label'),
                              style: TextStyle(color: dark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RoundedField(
                            child: TextFormField(
                              controller: _creditController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: fieldDecoration(context, hint: 'Credits'),
                              style: TextStyle(color: dark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _letters.map((l) {
                        final selected = _letter == l;
                        return ChoiceChip(
                          label: Text(l),
                          selected: selected,
                          onSelected: (_) => setState(() => _letter = l),
                          selectedColor: primaryColor.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: selected ? primaryColor : (dark ? Colors.white70 : Colors.black87),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _addCourse,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Course'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (courses.isNotEmpty) ...[
                Text(
                  'Courses',
                  style: TextStyle(fontWeight: FontWeight.w700, color: dark ? Colors.white : primaryColor),
                ),
                const SizedBox(height: 8),
                ...courses.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.courseName,
                                      style: TextStyle(fontWeight: FontWeight.w600, color: dark ? Colors.white : Colors.black87)),
                                  Text(
                                    '${c.semesterLabel} \u2022 ${c.creditHours} credits \u2022 GP ${c.gradePoint.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 11, color: dark ? Colors.white54 : Colors.black45),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: c.id == null
                                  ? null
                                  : () => ref.read(gpaProvider.notifier).deleteCourse(c.id!),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
