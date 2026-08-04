class TaskEntry {
  final int? id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final String priority; // 'High', 'Medium', 'Low'
  final bool isCompleted;
  final String notes;

  const TaskEntry({
    this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.priority = 'Medium',
    this.isCompleted = false,
    this.notes = '',
  });

  /// Higher = more urgent. Used to sort tasks by priority when the caller
  /// wants urgency-first ordering instead of due-date-first.
  static const Map<String, int> _priorityWeight = {'High': 3, 'Medium': 2, 'Low': 1};
  int get priorityWeight => _priorityWeight[priority] ?? 2;

  /// Sorts High > Medium > Low, and by due date within the same priority.
  static int comparePriorityThenDueDate(TaskEntry a, TaskEntry b) {
    final byPriority = b.priorityWeight.compareTo(a.priorityWeight);
    if (byPriority != 0) return byPriority;
    return a.dueDate.compareTo(b.dueDate);
  }

  TaskEntry copyWith({
    int? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    String? priority,
    bool? isCompleted,
    String? notes,
  }) {
    return TaskEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
    };
  }

  factory TaskEntry.fromMap(Map<String, dynamic> map) {
    return TaskEntry(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? '') ?? DateTime.now(),
      priority: map['priority'] as String? ?? 'Medium',
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      notes: map['notes'] as String? ?? '',
    );
  }
}
