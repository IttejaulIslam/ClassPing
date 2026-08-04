import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/routine/domain/class_entry.dart';
import '../../features/tasks/domain/task_entry.dart';

/// All routine and task data lives in a local SQLite file on-device.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'classping.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createClassEntriesTable(db);
        await _createTasksTable(db);
        await _createAttendanceTable(db);
        await _createExamsTable(db);
        await _createCourseGradesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTasksTable(db);
        }
        if (oldVersion < 3) {
          await _createAttendanceTable(db);
          await _createExamsTable(db);
          await _createCourseGradesTable(db);
        }
      },
      onOpen: (db) async {
        await _createTasksTable(db);
        await _createAttendanceTable(db);
        await _createExamsTable(db);
        await _createCourseGradesTable(db);
      },
    );
  }

  static Future<void> _createClassEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS class_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        startHour INTEGER NOT NULL,
        startMinute INTEGER NOT NULL,
        endHour INTEGER NOT NULL,
        endMinute INTEGER NOT NULL,
        room TEXT,
        instructor TEXT,
        reminderMinutesBefore INTEGER NOT NULL DEFAULT 10
      )
    ''');
  }

  static Future<void> _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'Medium',
        isCompleted INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');
  }

  /// One row per attended/missed occurrence of a class, keyed to the
  /// routine's [ClassEntry.id] so attendance % can be computed per subject.
  static Future<void> _createAttendanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        classEntryId INTEGER NOT NULL,
        subject TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'present',
        UNIQUE(classEntryId, date)
      )
    ''');
  }

  /// Exams are tracked separately from tasks so "Exam Mode" can show a
  /// dedicated countdown/checklist view.
  static Future<void> _createExamsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        examDate TEXT NOT NULL,
        examType TEXT NOT NULL DEFAULT 'Midterm',
        room TEXT,
        syllabus TEXT,
        isPrepared INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// One row per course per semester for the GPA/CGPA calculator.
  static Future<void> _createCourseGradesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS course_grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseName TEXT NOT NULL,
        semesterLabel TEXT NOT NULL,
        creditHours REAL NOT NULL,
        gradePoint REAL NOT NULL
      )
    ''');
  }

  // --- Class Entries ---
  Future<int> insertClassEntry(ClassEntry entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    return db.insert('class_entries', map);
  }

  Future<int> updateClassEntry(ClassEntry entry) async {
    final db = await database;
    return db.update(
      'class_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteClassEntry(int id) async {
    final db = await database;
    return db.delete('class_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ClassEntry>> getAllClassEntries() async {
    final db = await database;
    final rows = await db.query(
      'class_entries',
      orderBy: 'dayOfWeek ASC, startHour ASC, startMinute ASC',
    );
    return rows.map(ClassEntry.fromMap).toList();
  }

  // --- Tasks ---
  Future<int> insertTask(TaskEntry task) async {
    final db = await database;
    final map = task.toMap()..remove('id');
    return db.insert('tasks', map);
  }

  Future<int> updateTask(TaskEntry task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleTaskCompleted(int id, bool isCompleted) async {
    final db = await database;
    return db.update(
      'tasks',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TaskEntry>> getAllTasks() async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      orderBy: 'isCompleted ASC, dueDate ASC',
    );
    return rows.map(TaskEntry.fromMap).toList();
  }

  // --- Attendance ---
  Future<void> markAttendance({
    required int classEntryId,
    required String subject,
    required DateTime date,
    required String status, // 'present' | 'absent'
  }) async {
    final db = await database;
    final dateKey = _dateOnly(date);
    await db.insert(
      'attendance',
      {
        'classEntryId': classEntryId,
        'subject': subject,
        'date': dateKey,
        'status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllAttendance() async {
    final db = await database;
    return db.query('attendance', orderBy: 'date DESC');
  }

  Future<void> deleteAttendanceRecord(int id) async {
    final db = await database;
    await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  static String _dateOnly(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // --- Exams ---
  Future<int> insertExam(Map<String, Object?> exam) async {
    final db = await database;
    final map = Map<String, Object?>.from(exam)..remove('id');
    return db.insert('exams', map);
  }

  Future<int> updateExam(Map<String, Object?> exam) async {
    final db = await database;
    return db.update('exams', exam, where: 'id = ?', whereArgs: [exam['id']]);
  }

  Future<int> deleteExam(int id) async {
    final db = await database;
    return db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getAllExams() async {
    final db = await database;
    return db.query('exams', orderBy: 'examDate ASC');
  }

  // --- Course grades (GPA/CGPA) ---
  Future<int> insertCourseGrade(Map<String, Object?> grade) async {
    final db = await database;
    final map = Map<String, Object?>.from(grade)..remove('id');
    return db.insert('course_grades', map);
  }

  Future<int> deleteCourseGrade(int id) async {
    final db = await database;
    return db.delete('course_grades', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getAllCourseGrades() async {
    final db = await database;
    return db.query('course_grades', orderBy: 'id DESC');
  }

  // --- Full raw export/import, used by BackupService ---
  Future<Map<String, List<Map<String, Object?>>>> exportAllTables() async {
    final db = await database;
    return {
      'class_entries': await db.query('class_entries'),
      'tasks': await db.query('tasks'),
      'attendance': await db.query('attendance'),
      'exams': await db.query('exams'),
      'course_grades': await db.query('course_grades'),
    };
  }

  /// Wipes and reinserts every table from a previously exported map. Used by
  /// BackupService.restoreFromJson(). IDs are dropped so autoincrement
  /// assigns fresh ones and avoids collisions with any existing data.
  Future<void> importAllTables(Map<String, List<Map<String, Object?>>> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'class_entries',
        'tasks',
        'attendance',
        'exams',
        'course_grades',
      ]) {
        await txn.delete(table);
        final rows = data[table] ?? const [];
        for (final row in rows) {
          final map = Map<String, Object?>.from(row)..remove('id');
          await txn.insert(table, map);
        }
      }
    });
  }
}
