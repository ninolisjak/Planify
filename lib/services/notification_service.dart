import 'package:flutter/material.dart';
import 'db_service.dart';

enum NotificationType { deadline, task, focusSession, material, info }

class AppNotification {
  final int? id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final int? relatedId; // ID izpita, naloge, itd.

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'type': type.name,
      'is_read': isRead ? 1 : 0,
      'related_id': relatedId,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.info,
      ),
      isRead: map['is_read'] == 1,
      relatedId: map['related_id'],
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.deadline:
        return Icons.event;
      case NotificationType.task:
        return Icons.assignment;
      case NotificationType.focusSession:
        return Icons.timer;
      case NotificationType.material:
        return Icons.photo_library;
      case NotificationType.info:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.deadline:
        return Colors.red;
      case NotificationType.task:
        return Colors.orange;
      case NotificationType.focusSession:
        return Colors.green;
      case NotificationType.material:
        return Colors.blue;
      case NotificationType.info:
        return Colors.grey;
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DBService _dbService = DBService();

  /// Ustvari tabelo za obvestila
  Future<void> createNotificationsTable() async {
    final db = await _dbService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now')),
        type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        related_id INTEGER
      )
    ''');
  }

  /// Dodaj obvestilo
  Future<int> addNotification(AppNotification notification) async {
    await createNotificationsTable();
    final db = await _dbService.database;
    final data = notification.toMap();
    data['user_id'] = _dbService.currentUserId;
    return await db.insert('app_notifications', data);
  }

  /// Pridobi vsa obvestila
  Future<List<AppNotification>> getNotifications() async {
    await createNotificationsTable();
    final db = await _dbService.database;
    final userId = _dbService.currentUserId;
    if (userId == null) return [];
    
    final result = await db.query(
      'app_notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    return result.map((e) => AppNotification.fromMap(e)).toList();
  }

  /// Pridobi število neprebranih obvestil
  Future<int> getUnreadCount() async {
    await createNotificationsTable();
    final db = await _dbService.database;
    final userId = _dbService.currentUserId;
    if (userId == null) return 0;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM app_notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    
    return result.first['count'] as int? ?? 0;
  }

  /// Označi obvestilo kot prebrano
  Future<void> markAsRead(int id) async {
    final db = await _dbService.database;
    await db.update(
      'app_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Označi vsa obvestila kot prebrana
  Future<void> markAllAsRead() async {
    final db = await _dbService.database;
    final userId = _dbService.currentUserId;
    if (userId == null) return;
    
    await db.update(
      'app_notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Izbriši obvestilo
  Future<void> deleteNotification(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'app_notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Izbriši vsa obvestila
  Future<void> deleteAllNotifications() async {
    final db = await _dbService.database;
    final userId = _dbService.currentUserId;
    if (userId == null) return;
    
    await db.delete(
      'app_notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ============ HELPER METODE ZA DODAJANJE OBVESTIL ============

  /// Obvestilo za nov izpitni rok
  Future<void> notifyDeadlineAdded(String subjectName, DateTime examDate) async {
    final daysUntil = examDate.difference(DateTime.now()).inDays;
    await addNotification(AppNotification(
      title: '📚 Nov izpitni rok dodan',
      body: '$subjectName - ${examDate.day}.${examDate.month}.${examDate.year} (čez $daysUntil dni)',
      createdAt: DateTime.now(),
      type: NotificationType.deadline,
    ));
  }

  /// Obvestilo za prihajajoči izpit
  Future<void> notifyUpcomingExam(String subjectName, int daysRemaining) async {
    String urgency = daysRemaining <= 1 ? '🚨' : (daysRemaining <= 3 ? '⚠️' : '📅');
    await addNotification(AppNotification(
      title: '$urgency Izpit čez $daysRemaining ${daysRemaining == 1 ? 'dan' : 'dni'}',
      body: 'Ne pozabi: Izpit iz $subjectName je kmalu!',
      createdAt: DateTime.now(),
      type: NotificationType.deadline,
    ));
  }

  /// Obvestilo za novo nalogo
  Future<void> notifyTaskAdded(String taskTitle, String subjectName, DateTime dueDate) async {
    await addNotification(AppNotification(
      title: '📝 Nova naloga dodana',
      body: '$taskTitle ($subjectName) - rok: ${dueDate.day}.${dueDate.month}.${dueDate.year}',
      createdAt: DateTime.now(),
      type: NotificationType.task,
    ));
  }

  /// Obvestilo za prihajajoči rok naloge
  Future<void> notifyUpcomingTask(String taskTitle, int daysRemaining) async {
    String urgency = daysRemaining <= 1 ? '🚨' : (daysRemaining <= 3 ? '⚠️' : '📋');
    await addNotification(AppNotification(
      title: '$urgency Rok naloge čez $daysRemaining ${daysRemaining == 1 ? 'dan' : 'dni'}',
      body: 'Naloga "$taskTitle" ima kmalu rok!',
      createdAt: DateTime.now(),
      type: NotificationType.task,
    ));
  }

  /// Obvestilo za končano focus sejo
  Future<void> notifyFocusSessionCompleted(int minutes, int cycles) async {
    await addNotification(AppNotification(
      title: '🎯 Focus seja končana!',
      body: 'Odlično! Opravil si $minutes minut fokusiranega učenja ($cycles ${cycles == 1 ? 'cikel' : 'ciklov'}).',
      createdAt: DateTime.now(),
      type: NotificationType.focusSession,
    ));
  }

  /// Obvestilo za novo gradivo
  Future<void> notifyMaterialAdded(String subjectName) async {
    await addNotification(AppNotification(
      title: '📷 Novo gradivo dodano',
      body: 'Dodal si novo gradivo za predmet $subjectName',
      createdAt: DateTime.now(),
      type: NotificationType.material,
    ));
  }

  /// Preveri in ustvari obvestila za prihajajoče roke
  Future<void> checkUpcomingDeadlines() async {
    final deadlines = await _dbService.getUpcomingExamDeadlines();
    final now = DateTime.now();
    
    for (var deadline in deadlines) {
      final examDate = DateTime.parse(deadline['exam_date']);
      final daysRemaining = examDate.difference(now).inDays;
      final subjectName = deadline['subject_name'] as String;
      
      // Obvestilo za izpite čez 1, 3 ali 7 dni
      if (daysRemaining == 1 || daysRemaining == 3 || daysRemaining == 7) {
        // Preveri, če obvestilo za ta rok že obstaja danes
        final alreadyNotified = await _hasRecentNotification(
          'Izpit čez $daysRemaining',
          subjectName,
        );
        if (!alreadyNotified) {
          await notifyUpcomingExam(subjectName, daysRemaining);
        }
      }
    }
  }

  /// Preveri in ustvari obvestila za prihajajoče naloge
  Future<void> checkUpcomingTasks() async {
    final tasks = await _dbService.getAllTasks();
    final now = DateTime.now();
    
    for (var task in tasks) {
      if (task['is_completed'] == 1) continue;
      
      final dueDate = DateTime.parse(task['due_date']);
      final daysRemaining = dueDate.difference(now).inDays;
      final taskTitle = task['title'] as String;
      
      // Obvestilo za naloge čez 1 ali 3 dni
      if (daysRemaining == 1 || daysRemaining == 3) {
        // Preveri, če obvestilo za to nalogo že obstaja danes
        final alreadyNotified = await _hasRecentNotification(
          'Rok naloge čez $daysRemaining',
          taskTitle,
        );
        if (!alreadyNotified) {
          await notifyUpcomingTask(taskTitle, daysRemaining);
        }
      }
    }
  }
  
  /// Preveri, če podobno obvestilo že obstaja danes
  Future<bool> _hasRecentNotification(String titleContains, String bodyContains) async {
    await createNotificationsTable();
    final db = await _dbService.database;
    final userId = _dbService.currentUserId;
    if (userId == null) return false;
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    
    final result = await db.rawQuery(
      '''SELECT COUNT(*) as count FROM app_notifications 
         WHERE user_id = ? AND title LIKE ? AND body LIKE ? AND created_at >= ?''',
      [userId, '%$titleContains%', '%$bodyContains%', startOfDay],
    );
    
    return (result.first['count'] as int? ?? 0) > 0;
  }
}
