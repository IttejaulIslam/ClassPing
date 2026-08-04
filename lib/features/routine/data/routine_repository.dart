import 'dart:developer' as developer;

import '../../../core/database/database_helper.dart';
import '../../../core/services/notification_service.dart';
import '../domain/class_entry.dart';

/// Thin coordination layer: every write to the local database is paired
/// with (re)scheduling or cancelling the matching local notification, so
/// the two never drift out of sync.
class RoutineRepository {
  RoutineRepository(this._db, this._notifications);

  final DatabaseHelper _db;
  final NotificationService _notifications;

  Future<List<ClassEntry>> getAll() => _db.getAllClassEntries();

  Future<ClassEntry> add(ClassEntry entry) async {
    final id = await _db.insertClassEntry(entry);
    final saved = entry.copyWith(id: id);
    try {
      await _notifications.scheduleWeeklyReminder(saved);
    } catch (e, st) {
      developer.log('Failed to schedule notification: $e', name: 'RoutineRepository', error: e, stackTrace: st);
    }
    return saved;
  }

  Future<void> update(ClassEntry entry) async {
    await _db.updateClassEntry(entry);
    try {
      await _notifications.scheduleWeeklyReminder(entry);
    } catch (e, st) {
      developer.log('Failed to reschedule notification: $e', name: 'RoutineRepository', error: e, stackTrace: st);
    }
  }

  Future<void> delete(ClassEntry entry) async {
    if (entry.id != null) {
      await _db.deleteClassEntry(entry.id!);
    }
    try {
      await _notifications.cancelReminder(entry);
    } catch (e, st) {
      developer.log('Failed to cancel notification: $e', name: 'RoutineRepository', error: e, stackTrace: st);
    }
  }
}
