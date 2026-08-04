import 'package:flutter_test/flutter_test.dart';
import 'package:classping/features/gpa/domain/course_grade.dart';

void main() {
  group('letterToGradePoint', () {
    test('maps standard letters to the 4.0 scale', () {
      expect(letterToGradePoint('A'), 4.0);
      expect(letterToGradePoint('A-'), 3.7);
      expect(letterToGradePoint('B+'), 3.3);
      expect(letterToGradePoint('F'), 0.0);
    });

    test('unknown letters default to 0.0', () {
      expect(letterToGradePoint('Z'), 0.0);
    });
  });

  group('GpaCalculator.computeGpa', () {
    test('returns 0 for an empty course list', () {
      expect(GpaCalculator.computeGpa([]), 0.0);
    });

    test('computes a simple credit-weighted average', () {
      final courses = [
        const CourseGrade(courseName: 'A', semesterLabel: 'S1', creditHours: 3, gradePoint: 4.0),
        const CourseGrade(courseName: 'B', semesterLabel: 'S1', creditHours: 3, gradePoint: 3.0),
      ];
      // (3*4.0 + 3*3.0) / 6 = 3.5
      expect(GpaCalculator.computeGpa(courses), 3.5);
    });

    test('weights higher-credit courses more heavily', () {
      final courses = [
        const CourseGrade(courseName: 'A', semesterLabel: 'S1', creditHours: 1, gradePoint: 4.0),
        const CourseGrade(courseName: 'B', semesterLabel: 'S1', creditHours: 3, gradePoint: 2.0),
      ];
      // (1*4.0 + 3*2.0) / 4 = 2.5
      expect(GpaCalculator.computeGpa(courses), 2.5);
    });
  });

  group('GpaCalculator.computeSemesterBreakdown', () {
    test('computes running CGPA across semesters in order', () {
      final courses = [
        const CourseGrade(courseName: 'A', semesterLabel: 'S1', creditHours: 3, gradePoint: 4.0),
        const CourseGrade(courseName: 'B', semesterLabel: 'S2', creditHours: 3, gradePoint: 2.0),
      ];
      final result = GpaCalculator.computeSemesterBreakdown(courses);

      expect(result.length, 2);
      expect(result[0].semester, 'S1');
      expect(result[0].gpa, 4.0);
      expect(result[0].cgpa, 4.0);
      expect(result[1].semester, 'S2');
      expect(result[1].gpa, 2.0);
      // running CGPA after both semesters: (3*4.0 + 3*2.0) / 6 = 3.0
      expect(result[1].cgpa, 3.0);
    });
  });
}
