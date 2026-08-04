import 'package:flutter_test/flutter_test.dart';
import 'package:classping/features/tasks/domain/task_entry.dart';

void main() {
  group('TaskEntry.comparePriorityThenDueDate', () {
    test('sorts High before Medium before Low', () {
      final low = TaskEntry(title: 'Low', subject: 'X', dueDate: DateTime(2026, 1, 10), priority: 'Low');
      final medium = TaskEntry(title: 'Medium', subject: 'X', dueDate: DateTime(2026, 1, 10), priority: 'Medium');
      final high = TaskEntry(title: 'High', subject: 'X', dueDate: DateTime(2026, 1, 10), priority: 'High');

      final sorted = [low, high, medium]..sort(TaskEntry.comparePriorityThenDueDate);

      expect(sorted.map((t) => t.title).toList(), ['High', 'Medium', 'Low']);
    });

    test('breaks ties within the same priority by earliest due date', () {
      final later = TaskEntry(title: 'Later', subject: 'X', dueDate: DateTime(2026, 2, 1), priority: 'High');
      final sooner = TaskEntry(title: 'Sooner', subject: 'X', dueDate: DateTime(2026, 1, 1), priority: 'High');

      final sorted = [later, sooner]..sort(TaskEntry.comparePriorityThenDueDate);

      expect(sorted.map((t) => t.title).toList(), ['Sooner', 'Later']);
    });

    test('unrecognized priority strings default to Medium weight', () {
      final task = TaskEntry(title: 'Odd', subject: 'X', dueDate: DateTime(2026, 1, 1), priority: 'Urgent!!');
      expect(task.priorityWeight, TaskEntry(title: '', subject: '', dueDate: DateTime(2026), priority: 'Medium').priorityWeight);
    });
  });
}
