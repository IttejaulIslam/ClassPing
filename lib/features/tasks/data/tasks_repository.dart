import '../../../core/database/database_helper.dart';
import '../domain/task_entry.dart';

class TasksRepository {
  final DatabaseHelper _db;
  TasksRepository(this._db);

  Future<List<TaskEntry>> getAll() => _db.getAllTasks();

  Future<TaskEntry> add(TaskEntry task) async {
    final id = await _db.insertTask(task);
    return task.copyWith(id: id);
  }

  Future<void> update(TaskEntry task) => _db.updateTask(task);

  Future<void> delete(int id) => _db.deleteTask(id);

  Future<void> toggleCompleted(int id, bool isCompleted) =>
      _db.toggleTaskCompleted(id, isCompleted);
}
