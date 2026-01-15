import 'package:flutter/material.dart';
import '../services/db_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final String subjectName;
  final String subjectColor;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.subjectName,
    required this.subjectColor,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final DBService _dbService = DBService();
  Map<String, dynamic>? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final task = await _dbService.getTaskById(widget.taskId);
    if (mounted) {
      setState(() {
        _task = task;
        _isLoading = false;
      });
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Future<void> _toggleComplete() async {
    if (_task == null) return;
    
    final newStatus = _task!['is_completed'] == 1 ? 0 : 1;
    await _dbService.updateTaskStatus(widget.taskId, newStatus == 1);
    await _loadTask();
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izbriši nalogo'),
        content: const Text('Ali res želiš izbrisati to nalogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Prekliči'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Izbriši', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteTask(widget.taskId);
      if (mounted) {
        Navigator.pop(context, true); // true = deleted
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = _getColorFromHex(widget.subjectColor);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Podrobnosti naloge'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFFEC407A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _task == null
              ? const Center(child: Text('Naloga ni najdena'))
              : _buildContent(isDark, subjectColor),
      floatingActionButton: _task != null
          ? FloatingActionButton.extended(
              onPressed: _toggleComplete,
              backgroundColor: _task!['is_completed'] == 1 ? Colors.orange : Colors.green,
              icon: Icon(
                _task!['is_completed'] == 1 ? Icons.refresh : Icons.check,
                color: Colors.white,
              ),
              label: Text(
                _task!['is_completed'] == 1 ? 'Označi kot nedokončano' : 'Označi kot dokončano',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(bool isDark, Color subjectColor) {
    final dueDate = DateTime.parse(_task!['due_date']);
    final now = DateTime.now();
    final daysRemaining = dueDate.difference(now).inDays;
    final isOverdue = daysRemaining < 0 && _task!['is_completed'] != 1;
    final isCompleted = _task!['is_completed'] == 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status kartica
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : isOverdue
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [subjectColor.withOpacity(0.8), subjectColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle
                          : isOverdue
                              ? Icons.warning
                              : Icons.assignment,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isCompleted
                            ? 'DOKONČANO ✓'
                            : isOverdue
                                ? 'ZAMUJENO!'
                                : daysRemaining == 0
                                    ? 'ROK DANES!'
                                    : daysRemaining == 1
                                        ? 'ROK JUTRI'
                                        : 'Še $daysRemaining dni',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Naslov naloge
          Text(
            'Naslov',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              _task!['title'] ?? 'Brez naslova',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Predmet
          Text(
            'Predmet',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: subjectColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.subjectName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rok
          Text(
            'Rok oddaje',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: isOverdue ? Colors.red : (isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(width: 12),
                Text(
                  '${dueDate.day}.${dueDate.month}.${dueDate.year}',
                  style: TextStyle(
                    color: isOverdue
                        ? Colors.red
                        : (isDark ? Colors.white : Colors.black87),
                    fontSize: 16,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Opis (če obstaja)
          if (_task!['description'] != null && _task!['description'].toString().isNotEmpty) ...[
            Text(
              'Opis / Kaj je za narediti',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                _task!['description'],
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 100), // Prostor za FAB
        ],
      ),
    );
  }
}
