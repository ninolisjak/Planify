import 'package:flutter/material.dart';
import '../services/db_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final DBService _dbService = DBService();
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _dbService.getAllTasks();
      final subjects = await _dbService.getAllSubjects();
      setState(() {
        _allTasks = tasks;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka pri nalaganju: $e')),
        );
      }
    }
  }

  String _getSubjectName(int? subjectId) {
    if (subjectId == null) return 'Brez predmeta';
    final subject = _subjects.firstWhere(
      (s) => s['id'] == subjectId,
      orElse: () => {'name': 'Neznan predmet'},
    );
    return subject['name'] ?? 'Neznan predmet';
  }

  String? _getSubjectColor(int? subjectId) {
    if (subjectId == null) return null;
    final subject = _subjects.firstWhere(
      (s) => s['id'] == subjectId,
      orElse: () => {},
    );
    return subject['color'];
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF8E24AA);
    }
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF8E24AA);
    }
  }

  Future<void> _toggleTaskCompletion(Map<String, dynamic> task) async {
    final newStatus = (task['is_completed'] ?? 0) == 1 ? 0 : 1;
    await _dbService.updateTask(task['id'], {'is_completed': newStatus});
    _loadData();
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izbriši nalogo'),
        content: Text('Ali ste prepričani, da želite izbrisati nalogo "${task['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Izbriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteTask(task['id']);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filtriraj samo nedokončane naloge
    final incompleteTasks = _allTasks
        .where((t) => (t['is_completed'] ?? 0) == 0)
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Razdelitev na ta teden (<7 dni) in naslednji teden (7-14 dni)
    final thisWeekTasks = incompleteTasks.where((t) {
      final dueDate = DateTime.parse(t['due_date']);
      final diff = dueDate.difference(today).inDays;
      return diff >= 0 && diff < 7;
    }).toList();

    final nextWeekTasks = incompleteTasks.where((t) {
      final dueDate = DateTime.parse(t['due_date']);
      final diff = dueDate.difference(today).inDays;
      return diff >= 7 && diff < 14;
    }).toList();

    final overdueTasks = incompleteTasks.where((t) {
      final dueDate = DateTime.parse(t['due_date']);
      return dueDate.isBefore(today);
    }).toList();

    final laterTasks = incompleteTasks.where((t) {
      final dueDate = DateTime.parse(t['due_date']);
      final diff = dueDate.difference(today).inDays;
      return diff >= 14;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Naloge'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : incompleteTasks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Zamujene naloge
                      if (overdueTasks.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Zamujene',
                          Icons.warning_amber_rounded,
                          Colors.red,
                          overdueTasks.length,
                          isDark,
                        ),
                        ...overdueTasks.map((t) => _buildTaskCard(t, isDark, isOverdue: true)),
                        const SizedBox(height: 16),
                      ],

                      // Ta teden (0-6 dni)
                      if (thisWeekTasks.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Ta teden',
                          Icons.calendar_today,
                          Colors.orange,
                          thisWeekTasks.length,
                          isDark,
                        ),
                        ...thisWeekTasks.map((t) => _buildTaskCard(t, isDark)),
                        const SizedBox(height: 16),
                      ],

                      // Naslednji teden (7-13 dni)
                      if (nextWeekTasks.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Naslednji teden',
                          Icons.calendar_view_week,
                          Colors.blue,
                          nextWeekTasks.length,
                          isDark,
                        ),
                        ...nextWeekTasks.map((t) => _buildTaskCard(t, isDark)),
                        const SizedBox(height: 16),
                      ],

                      // Kasneje (14+ dni)
                      if (laterTasks.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Kasneje',
                          Icons.calendar_month,
                          Colors.green,
                          laterTasks.length,
                          isDark,
                        ),
                        ...laterTasks.map((t) => _buildTaskCard(t, isDark)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ni nalog',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodajte naloge pri posameznih predmetih',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isDark, {bool isOverdue = false}) {
    final dueDate = DateTime.parse(task['due_date']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysRemaining = dueDate.difference(today).inDays;

    final subjectName = _getSubjectName(task['subject_id']);
    final subjectColor = _getColorFromHex(_getSubjectColor(task['subject_id']));

    Color statusColor;
    String statusText;

    if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Zamujeno';
    } else if (daysRemaining == 0) {
      statusColor = Colors.red;
      statusText = 'Danes';
    } else if (daysRemaining == 1) {
      statusColor = Colors.orange;
      statusText = 'Jutri';
    } else if (daysRemaining < 7) {
      statusColor = Colors.orange;
      statusText = '$daysRemaining dni';
    } else {
      statusColor = Colors.blue;
      statusText = '$daysRemaining dni';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              subjectColor.withOpacity(0.08),
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Checkbox(
            value: false,
            onChanged: (_) => _toggleTaskCompletion(task),
            activeColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            task['title'],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subjectName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    '${dueDate.day}.${dueDate.month}.${dueDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (task['description'] != null && task['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    task['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[500]),
            onPressed: () => _deleteTask(task),
          ),
        ),
      ),
    );
  }
}
