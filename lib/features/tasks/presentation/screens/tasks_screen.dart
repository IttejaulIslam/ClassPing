import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/task_entry.dart';
import '../providers/tasks_providers.dart';

enum TaskFilter { all, pending, completed }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskFilter _selectedFilter = TaskFilter.pending;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final tasksAsync = ref.watch(tasksProvider);

    return AppBackground(
      bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'Tasks & Assignments'),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 85),
          child: FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: () => context.push('/tasks/add'),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        body: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load tasks.\n$err',
                textAlign: TextAlign.center,
                style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
          data: (tasks) {
            final totalCount = tasks.length;
            final completedCount = tasks.where((t) => t.isCompleted).length;
            final pendingCount = totalCount - completedCount;
            final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

            final filteredTasks = tasks.where((t) {
              if (_selectedFilter == TaskFilter.pending && t.isCompleted) return false;
              if (_selectedFilter == TaskFilter.completed && !t.isCompleted) return false;
              if (_query.isNotEmpty) {
                final q = _query.toLowerCase();
                return t.title.toLowerCase().contains(q) || t.subject.toLowerCase().contains(q);
              }
              return true;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                // Header Dashboard Progress Card
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderColor: primaryColor.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ASSIGNMENT PROGRESS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: secondaryColor,
                            ),
                          ),
                          Text(
                            '$completedCount / $totalCount completed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor:
                              dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(secondaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pendingCount == 0
                            ? 'All caught up! Excellent job! 🎉'
                            : 'You have $pendingCount task${pendingCount == 1 ? '' : 's'} remaining.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: dark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintText: 'Search tasks or subject\u2026',
                      hintStyle: TextStyle(color: dark ? Colors.white38 : Colors.black38),
                      prefixIcon: Icon(Icons.search, size: 20, color: dark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Filter Segment Buttons
                Row(
                  children: TaskFilter.values.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    String label;
                    if (filter == TaskFilter.pending) {
                      label = 'Pending ($pendingCount)';
                    } else if (filter == TaskFilter.completed) {
                      label = 'Done ($completedCount)';
                    } else {
                      label = 'All ($totalCount)';
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (dark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: primaryColor,
                          backgroundColor: dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          side: BorderSide.none,
                          showCheckmark: false,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                if (filteredTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedFilter == TaskFilter.completed
                                ? Icons.task_alt
                                : Icons.assignment_outlined,
                            size: 40,
                            color: dark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilter == TaskFilter.completed
                                ? 'No completed tasks yet.'
                                : 'No pending tasks! Tap + to create one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TaskTile(task: task),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final TaskEntry task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);

    final now = DateTime.now();
    final isOverdue = !task.isCompleted && task.dueDate.isBefore(now);
    final isToday = !task.isCompleted &&
        task.dueDate.year == now.year &&
        task.dueDate.month == now.month &&
        task.dueDate.day == now.day;

    Color dueColor = dark ? Colors.white60 : Colors.black54;
    String dueLabel = DateFormat('MMM d, h:mm a').format(task.dueDate);
    if (isOverdue) {
      dueColor = Colors.redAccent;
      dueLabel = 'Overdue \u2022 ${DateFormat('MMM d').format(task.dueDate)}';
    } else if (isToday) {
      dueColor = Colors.orangeAccent;
      dueLabel = 'Due Today \u2022 ${DateFormat('h:mm a').format(task.dueDate)}';
    }

    Color priorityColor;
    if (task.priority == 'High') {
      priorityColor = Colors.redAccent;
    } else if (task.priority == 'Medium') {
      priorityColor = Colors.orangeAccent;
    } else {
      priorityColor = Colors.blueAccent;
    }

    return Dismissible(
      key: ValueKey(task.id),
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task?'),
            content: Text('Remove "${task.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        if (task.id != null) {
          ref.read(tasksProvider.notifier).deleteTask(task.id!);
        }
      },
      child: GestureDetector(
        onTap: () => context.push('/tasks/edit', extra: task),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ref.read(tasksProvider.notifier).toggleTask(task),
                icon: Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: task.isCompleted
                      ? secondaryColor
                      : (dark ? Colors.white54 : Colors.black45),
                  size: 24,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? (dark ? Colors.white38 : Colors.black38)
                            : (dark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (task.subject.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.subject,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            dueLabel,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dueColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
