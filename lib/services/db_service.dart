import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;

  // Getter za trenutni user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('planify.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Dodaj stolpec type v sync_status če ne obstaja
      try {
        await db.execute('ALTER TABLE sync_status ADD COLUMN type TEXT');
      } catch (e) {
        // Stolpec že obstaja
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles(
        id TEXT PRIMARY KEY,
        email TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        name TEXT NOT NULL,
        professor TEXT,
        color TEXT,
        icon TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        subject_id INTEGER,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        due_date TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        subject_id INTEGER,
        duration_minutes INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        minutes_focus INTEGER NOT NULL,
        minutes_break INTEGER NOT NULL,
        completed_cycles INTEGER NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        task_id INTEGER,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        notify_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE weather_cache(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        date TEXT NOT NULL,
        temperature REAL NOT NULL,
        condition TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        local_task_id INTEGER,
        google_event_id TEXT,
        type TEXT,
        last_sync TEXT DEFAULT (datetime('now'))
      )
    ''');
  }


  Future<int> insertSubject(Map<String, dynamic> row) async {
    final db = await database;
    // Dodaj user_id če ni prisoten
    row['user_id'] = currentUserId;
    return await db.insert('subjects', row);
  }

  Future<List<Map<String, dynamic>>> getAllSubjects() async {
    final db = await database;
    final userId = currentUserId;
    if (userId == null) return [];
    return await db.query('subjects', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at');
  }

  Future<int> updateSubject(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('subjects', row, where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return await db.delete('subjects', where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }

  
  Future<int> insertTask(Map<String, dynamic> row) async {
    final db = await database;
    row['user_id'] = currentUserId;
    return await db.insert('tasks', row);
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    final userId = currentUserId;
    if (userId == null) return [];
    return await db.query('tasks', where: 'user_id = ?', whereArgs: [userId], orderBy: 'due_date');
  }

  Future<List<Map<String, dynamic>>> getTasksForSubject(int subjectId) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'subject_id = ? AND user_id = ?',
      whereArgs: [subjectId, currentUserId],
      orderBy: 'due_date ASC',
    );
  }

  Future<int> updateTask(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('tasks', row, where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }


  Future<int> insertStudySession(Map<String, dynamic> row) async {
    final db = await database;
    row['user_id'] = currentUserId;
    return await db.insert('study_sessions', row);
  }

  Future<List<Map<String, dynamic>>> getAllStudySessions() async {
    final db = await database;
    final userId = currentUserId;
    if (userId == null) return [];
    return await db.query('study_sessions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
  }

  Future<int> deleteStudySession(int id) async {
    final db = await database;
    return await db.delete('study_sessions', where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }


  Future<int> insertFocusSession(Map<String, dynamic> row) async {
    final db = await database;
    row['user_id'] = currentUserId;
    return await db.insert('focus_sessions', row);
  }

  Future<List<Map<String, dynamic>>> getAllFocusSessions() async {
    final db = await database;
    final userId = currentUserId;
    if (userId == null) return [];
    return await db.query('focus_sessions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
  }

  Future<int> deleteFocusSession(int id) async {
    final db = await database;
    return await db.delete('focus_sessions', where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }

  
  Future<int> insertNotification(Map<String, dynamic> row) async {
    final db = await database;
    row['user_id'] = currentUserId;
    return await db.insert('notifications', row);
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    final userId = currentUserId;
    if (userId == null) return [];
    return await db.query('notifications', where: 'user_id = ?', whereArgs: [userId], orderBy: 'notify_at');
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete('notifications', where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }

 
  Future<int> insertWeather(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('weather_cache', row);
  }

  Future<List<Map<String, dynamic>>> getAllWeather() async {
    final db = await database;
    return await db.query('weather_cache', orderBy: 'date DESC');
  }

  Future<int> deleteWeather(int id) async {
    final db = await database;
    return await db.delete('weather_cache', where: 'id = ?', whereArgs: [id]);
  }


  Future<int> insertSyncStatus(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('sync_status', row);
  }

  Future<List<Map<String, dynamic>>> getAllSyncStatus() async {
    final db = await database;
    return await db.query('sync_status', orderBy: 'last_sync DESC');
  }

  Future<int> updateSyncStatus(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('sync_status', row, where: 'id = ?', whereArgs: [id]);
  }
  Future<int> insert(String table, Map<String, dynamic> row) async {
  final db = await database;
  return await db.insert(table, row);
}

  // === EXAM DEADLINES ===

  Future<void> createExamDeadlinesTable() async {
    final db = await database;
    
    // Preveri če tabela že obstaja
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='exam_deadlines'"
    );
    
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE exam_deadlines(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT,
          subject_id INTEGER,
          subject_name TEXT NOT NULL,
          exam_date TEXT NOT NULL,
          exam_time TEXT,
          duration_minutes INTEGER,
          location TEXT,
          notes TEXT,
          created_at TEXT DEFAULT (datetime('now')),
          FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
        )
      ''');
    }
  }

  Future<int> insertExamDeadline(Map<String, dynamic> row) async {
    final db = await database;
    row['user_id'] = currentUserId;
    return await db.insert('exam_deadlines', row);
  }

  Future<List<Map<String, dynamic>>> getAllExamDeadlines() async {
    final db = await database;
    final userId = currentUserId;
    if (userId == null) return [];
    return await db.query('exam_deadlines', where: 'user_id = ?', whereArgs: [userId], orderBy: 'exam_date ASC');
  }

  Future<List<Map<String, dynamic>>> getUpcomingExamDeadlines() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final userId = currentUserId;
    if (userId == null) return [];
    return await db.query(
      'exam_deadlines',
      where: 'exam_date >= ? AND user_id = ?',
      whereArgs: [now, userId],
      orderBy: 'exam_date ASC',
    );
  }

  Future<int> updateExamDeadline(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('exam_deadlines', row, where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }

  Future<int> deleteExamDeadline(int id) async {
    final db = await database;
    return await db.delete('exam_deadlines', where: 'id = ? AND user_id = ?', whereArgs: [id, currentUserId]);
  }

  // ============ SYNC STATUS (Google Calendar) ============

  Future<void> saveSyncStatus(int localId, String googleEventId, String type) async {
    final db = await database;
    await db.insert('sync_status', {
      'user_id': currentUserId,
      'local_task_id': localId,
      'google_event_id': googleEventId,
      'type': type, // 'deadline' ali 'task'
      'last_sync': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getGoogleEventId(int localId, String type) async {
    final db = await database;
    final result = await db.query(
      'sync_status',
      where: 'local_task_id = ? AND type = ? AND user_id = ?',
      whereArgs: [localId, type, currentUserId],
    );
    if (result.isNotEmpty) {
      return result.first['google_event_id'] as String?;
    }
    return null;
  }

  Future<void> deleteSyncStatus(int localId, String type) async {
    final db = await database;
    await db.delete(
      'sync_status',
      where: 'local_task_id = ? AND type = ? AND user_id = ?',
      whereArgs: [localId, type, currentUserId],
    );
  }
}
