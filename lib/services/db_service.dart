import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;

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
      version: 1,
      onCreate: _createDB,
    );
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
        last_sync TEXT DEFAULT (datetime('now'))
      )
    ''');
  }


  Future<int> insertSubject(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('subjects', row);
  }

  Future<List<Map<String, dynamic>>> getAllSubjects() async {
    final db = await database;
    return await db.query('subjects', orderBy: 'created_at');
  }

  Future<int> updateSubject(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('subjects', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  
  Future<int> insertTask(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('tasks', row);
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'due_date');
  }

  Future<int> updateTask(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('tasks', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }


  Future<int> insertStudySession(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('study_sessions', row);
  }

  Future<List<Map<String, dynamic>>> getAllStudySessions() async {
    final db = await database;
    return await db.query('study_sessions', orderBy: 'date DESC');
  }

  Future<int> deleteStudySession(int id) async {
    final db = await database;
    return await db.delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  }


  Future<int> insertFocusSession(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('focus_sessions', row);
  }

  Future<List<Map<String, dynamic>>> getAllFocusSessions() async {
    final db = await database;
    return await db.query('focus_sessions', orderBy: 'date DESC');
  }

  Future<int> deleteFocusSession(int id) async {
    final db = await database;
    return await db.delete('focus_sessions', where: 'id = ?', whereArgs: [id]);
  }

  
  Future<int> insertNotification(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('notifications', row);
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    return await db.query('notifications', orderBy: 'notify_at');
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
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
}
