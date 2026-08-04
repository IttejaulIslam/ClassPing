class CourseGrade {
  final int? id;
  final String courseName;
  final String semesterLabel;
  final double creditHours;
  final double gradePoint; // 0.0 - 4.0 scale

  const CourseGrade({
    this.id,
    required this.courseName,
    required this.semesterLabel,
    required this.creditHours,
    required this.gradePoint,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'courseName': courseName,
        'semesterLabel': semesterLabel,
        'creditHours': creditHours,
        'gradePoint': gradePoint,
      };

  factory CourseGrade.fromMap(Map<String, Object?> map) => CourseGrade(
        id: map['id'] as int?,
        courseName: map['courseName'] as String,
        semesterLabel: map['semesterLabel'] as String,
        creditHours: (map['creditHours'] as num).toDouble(),
        gradePoint: (map['gradePoint'] as num).toDouble(),
      );
}

/// Standard 4.0-scale letter grade -> grade point map, used by the grade
/// picker in the calculator UI. Kept as a plain function (not hardcoded in
/// the widget) so it's independently testable.
/// East Delta University's official grading scale (Percentage -> Letter
/// -> GPA). Note: EDU's scale has no A+ (top grade is A = 4.0) and no D-.
double letterToGradePoint(String letter) {
  const table = {
    'A': 4.00, 'A-': 3.70,
    'B+': 3.30, 'B': 3.00, 'B-': 2.70,
    'C+': 2.30, 'C': 2.00, 'C-': 1.70,
    'D+': 1.30, 'D': 1.00,
    'F': 0.00,
  };
  return table[letter] ?? 0.0;
}

/// Pure GPA/CGPA math, factored out so it can be unit tested without any
/// Flutter/widget dependency.
class GpaCalculator {
  /// Weighted average grade point across the given courses:
  /// sum(credit * gradePoint) / sum(credit)
  static double computeGpa(List<CourseGrade> courses) {
    if (courses.isEmpty) return 0.0;
    final totalCredits = courses.fold<double>(0, (sum, c) => sum + c.creditHours);
    if (totalCredits == 0) return 0.0;
    final weightedSum = courses.fold<double>(0, (sum, c) => sum + c.creditHours * c.gradePoint);
    return weightedSum / totalCredits;
  }

  /// Groups courses by semesterLabel and computes each semester's GPA plus
  /// the running CGPA up to and including that semester (in first-seen order).
  static List<({String semester, double gpa, double cgpa})> computeSemesterBreakdown(
    List<CourseGrade> courses,
  ) {
    final order = <String>[];
    final bySemester = <String, List<CourseGrade>>{};
    for (final c in courses) {
      if (!bySemester.containsKey(c.semesterLabel)) order.add(c.semesterLabel);
      bySemester.putIfAbsent(c.semesterLabel, () => []).add(c);
    }

    final result = <({String semester, double gpa, double cgpa})>[];
    final seenSoFar = <CourseGrade>[];
    for (final sem in order) {
      final semCourses = bySemester[sem]!;
      seenSoFar.addAll(semCourses);
      result.add((
        semester: sem,
        gpa: computeGpa(semCourses),
        cgpa: computeGpa(seenSoFar),
      ));
    }
    return result;
  }
}
