import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock obvestila - zamenjaj s pravimi iz baze/Firebase
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Rok za oddajo projektne naloge',
      body: 'Projekt iz programiranja je potrebno oddati do 20.1.2026',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.deadline,
    ),
    NotificationItem(
      id: '2',
      title: 'Focus seja končana',
      body: 'Odlično! Končal si 25-minutno focus sejo.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
      type: NotificationType.achievement,
    ),
    NotificationItem(
      id: '3',
      title: 'Novi flashcards',
      body: '15 kartic čaka na pregled v kompletu "Angleščina"',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.reminder,
    ),
    NotificationItem(
      id: '4',
      title: 'Izpit čez 3 dni',
      body: 'Ne pozabi: Izpit iz matematike je 16.1.2026',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.reminder,
    ),
  ];

  void _markAsRead(String id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n.id == id);
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return 'Pred ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Pred ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Pred ${difference.inDays} dni';
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
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Označi vse', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _NotificationCard(
                  notification: notification,
                  isDark: isDark,
                  onTap: () => _markAsRead(notification.id),
                  onDismiss: () => _deleteNotification(notification.id),
                  formatTime: _formatTime(notification.time),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Ni obvestil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ko boš imel nova obvestila, se bodo prikazala tukaj',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
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

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.deadline:
        return Icons.event;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.reminder:
        return Icons.notifications;
      case NotificationType.info:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.deadline:
        return Colors.red;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.info:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead
              ? BorderSide.none
              : BorderSide(
                  color: _getColor().withOpacity(0.5),
                  width: 2,
                ),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getColor(),
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
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
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

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    this.type = NotificationType.info,
  });
}

enum NotificationType {
  deadline,
  achievement,
  reminder,
  info,
}
