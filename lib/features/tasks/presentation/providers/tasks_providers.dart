import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_helper.dart';
import '../../data/tasks_repository.dart';
import '../../domain/task_entry.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(DatabaseHelper.instance);
});

class TasksNotifier extends AsyncNotifier<List<TaskEntry>> {
  @override
  Future<List<TaskEntry>> build() {
    return ref.read(tasksRepositoryProvider).getAll();
  }

  Future<void> addTask(TaskEntry task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tasksRepositoryProvider).add(task);
      return ref.read(tasksRepositoryProvider).getAll();
    });
  }

  Future<void> updateTask(TaskEntry task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tasksRepositoryProvider).update(task);
      return ref.read(tasksRepositoryProvider).getAll();
    });
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tasksRepositoryProvider).delete(id);
      return ref.read(tasksRepositoryProvider).getAll();
    });
  }

  Future<void> toggleTask(TaskEntry task) async {
    final updatedList = state.valueOrNull?.map((t) {
      if (t.id == task.id) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();

    if (updatedList != null) {
      state = AsyncValue.data(updatedList);
    }

    if (task.id != null) {
      await ref
          .read(tasksRepositoryProvider)
          .toggleCompleted(task.id!, !task.isCompleted);
    }
  }
}

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<TaskEntry>>(TasksNotifier.new);

final pendingTasksProvider = Provider<List<TaskEntry>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const [];
  return tasks.where((t) => !t.isCompleted).toList();
});
