import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/db_service.dart';
import 'task_detail_screen.dart';
import 'subject_detail_screen.dart';
import 'deadlines_screen.dart';
import 'subjects_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final DBService _dbService = DBService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    await _notificationService.markAsRead(id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    _loadNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    await _notificationService.deleteNotification(id);
    _loadNotifications();
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izbriši vsa obvestila'),
        content: const Text('Ali ste prepričani, da želite izbrisati vsa obvestila?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Izbriši vse'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.deleteAllNotifications();
      _loadNotifications();
    }
  }

  /// Navigiraj glede na tip obvestila
  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Označi kot prebrano
    if (!notification.isRead && notification.id != null) {
      await _markAsRead(notification.id!);
    }

    switch (notification.type) {
      case NotificationType.deadline:
        // Pojdi na stran Roki
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DeadlinesScreen(),
            ),
          );
        }
        break;
        
      case NotificationType.task:
        // Poskusi najti nalogo glede na naslov
        await _navigateToTask(notification);
        break;
        
      case NotificationType.material:
        // Poskusi najti predmet
        await _navigateToSubject(notification);
        break;
        
      case NotificationType.focusSession:
        // Za focus samo zapremo - uporabnik gre sam na tab
        Navigator.pop(context);
        break;
        
      case NotificationType.info:
      default:
        // Samo označi kot prebrano, brez navigacije
        break;
    }
  }

  Future<void> _navigateToTask(AppNotification notification) async {
    // Poiščemo nalogo po naslovu iz obvestila
    final tasks = await _dbService.getAllTasks();
    final subjects = await _dbService.getAllSubjects();
    
    // Poskusimo najti nalogo
    for (var task in tasks) {
      final taskTitle = task['title'] as String;
      if (notification.body.contains(taskTitle)) {
        // Najdemo predmet
        final subjectId = task['subject_id'];
        final subject = subjects.firstWhere(
          (s) => s['id'] == subjectId,
          orElse: () => {'name': 'Neznano', 'color': '#8E24AA'},
        );
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                taskId: task['id'],
                subjectName: subject['name'] ?? 'Neznano',
                subjectColor: subject['color'] ?? '#8E24AA',
              ),
            ),
          );
        }
        return;
      }
    }
    
    // Če ne najdemo, pojdimo na stran Roki
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DeadlinesScreen(),
        ),
      );
    }
  }

  Future<void> _navigateToSubject(AppNotification notification) async {
    final subjects = await _dbService.getAllSubjects();
    
    // Poskusimo najti predmet iz obvestila
    for (var subject in subjects) {
      final subjectName = subject['name'] as String;
      if (notification.body.contains(subjectName)) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectDetailScreen(
                subjectId: subject['id'],
                subjectName: subjectName,
                subjectColor: subject['color'] ?? '#8E24AA',
              ),
            ),
          );
        }
        return;
      }
    }
    
    // Če ne najdemo, pojdimo na stran Predmeti
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SubjectsScreen(),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Pravkar';
    } else if (difference.inMinutes < 60) {
      return 'Pred ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Pred ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Pred ${difference.inDays} ${difference.inDays == 1 ? 'dnem' : 'dnevi'}';
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Obvestila'),
            if (unreadCount > 0)
              Text(
                '$unreadCount neprebranih',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFFEC407A)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Preberi vse', style: TextStyle(color: Colors.white)),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _deleteAllNotifications,
              tooltip: 'Izbriši vse',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationCard(
                        notification: notification,
                        isDark: isDark,
                        onTap: () => _handleNotificationTap(notification),
                        onDismiss: () {
                          if (notification.id != null) {
                            _deleteNotification(notification.id!);
                          }
                        },
                        formatTime: _formatTime(notification.createdAt),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ni obvestil',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ko boš dodal izpitne roke, naloge ali končal focus sejo, se bodo obvestila prikazala tukaj.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final String formatTime;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
    required this.onDismiss,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: isDark 
            ? (notification.isRead ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D))
            : (notification.isRead ? Colors.white : Colors.white),
        elevation: notification.isRead ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead 
              ? BorderSide.none 
              : BorderSide(color: notification.color.withOpacity(0.5), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatTime,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
