import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/flashcard_service.dart';
import '../models/flashcard.dart';
import 'flashcard_decks_screen.dart';
import 'flashcard_edit_screen.dart';
import 'flashcard_study_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final String? subjectColor;
  final String? professorName;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.subjectColor,
    this.professorName,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final DBService _dbService = DBService();
  final FlashcardService _flashcardService = FlashcardService();

  late TabController _tabController;

  List<Map<String, dynamic>> _tasks = [];
  List<FlashcardDeck> _decks = [];
  bool _isLoadingTasks = true;
  bool _isLoadingDecks = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTasks(),
      _loadDecks(),
    ]);
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final data = await _dbService.getTasksForSubject(widget.subjectId);
      setState(() {
        _tasks = data;
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _loadDecks() async {
    setState(() => _isLoadingDecks = true);
    try {
      await _flashcardService.createTables();
      final decks = await _flashcardService.getAllDecks(subjectId: widget.subjectId);
      setState(() {
        _decks = decks;
        _isLoadingDecks = false;
      });
    } catch (e) {
      setState(() => _isLoadingDecks = false);
    }
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

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> _showAddEditTaskDialog({Map<String, dynamic>? task}) async {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?['title'] ?? '');
    final descriptionController = TextEditingController(text: task?['description'] ?? '');
    DateTime selectedDate = task != null
        ? DateTime.parse(task['due_date'])
        : DateTime.now().add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Uredi nalogo' : 'Dodaj nalogo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Ime naloge *',
                    hintText: 'npr. Preberi poglavje 5',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rok za oddajo: *',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    hintText: 'Dodatne informacije o nalogi...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Prekliči'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ime naloge je obvezno')),
                  );
                  return;
                }

                final data = {
                  'subject_id': widget.subjectId,
                  'title': title,
                  'type': 'assignment',
                  'due_date': selectedDate.toIso8601String(),
                  'description': descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  'is_completed': task?['is_completed'] ?? 0,
                };

                try {
                  if (isEditing) {
                    await _dbService.updateTask(task['id'], data);
                  } else {
                    await _dbService.insertTask(data);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTasks();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Naloga posodobljena' : 'Naloga dodana'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Napaka: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Shrani' : 'Dodaj'),
            ),
          ],
        ),
      ),
    );
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
      try {
        await _dbService.deleteTask(task['id']);
        _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Naloga izbrisana')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Napaka: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleTaskCompletion(Map<String, dynamic> task) async {
    final newStatus = (task['is_completed'] ?? 0) == 1 ? 0 : 1;
    await _dbService.updateTask(task['id'], {'is_completed': newStatus});
    _loadTasks();
  }

  void _showCreateDeckDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedColor = widget.subjectColor ?? '#9C27B0';

    final colors = [
      '#9C27B0', '#E91E63', '#F44336', '#FF9800',
      '#4CAF50', '#2196F3', '#3F51B5', '#607D8B',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nov komplet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ime kompleta',
                    hintText: 'npr. Poglavje 1',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Opis (opcijsko)',
                    hintText: 'npr. Besedišče za izpit',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Barva:', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hexToColor(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Prekliči'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final deck = FlashcardDeck(
                  subjectId: widget.subjectId,
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  color: selectedColor,
                );

                await _flashcardService.insertDeck(deck);
                Navigator.pop(context);
                _loadDecks();
              },
              child: const Text('Ustvari'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getColorFromHex(widget.subjectColor);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Naloge'),
            Tab(icon: Icon(Icons.style), text: 'Flashcards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksTab(isDark),
          _buildFlashcardsTab(isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditTaskDialog();
          } else {
            _showCreateDeckDialog();
          }
        },
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return Text(_tabController.index == 0 ? 'Dodaj nalogo' : 'Nov komplet');
          },
        ),
      ),
    );
  }

  Widget _buildTasksTab(bool isDark) {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
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
              'Dodajte svojo prvo nalogo',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Razdelimo na nedokončane in dokončane
    final incomplete = _tasks.where((t) => (t['is_completed'] ?? 0) == 0).toList();
    final completed = _tasks.where((t) => (t['is_completed'] ?? 0) == 1).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (incomplete.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Za narediti (${incomplete.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...incomplete.map((task) => _buildTaskCard(task, isDark)),
        ],
        if (completed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'Dokončane (${completed.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          ...completed.map((task) => _buildTaskCard(task, isDark, isCompleted: true)),
        ],
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isDark, {bool isCompleted = false}) {
    final dueDate = DateTime.parse(task['due_date']);
    final now = DateTime.now();
    final daysRemaining = dueDate.difference(now).inDays;
    final isOverdue = daysRemaining < 0 && !isCompleted;
    final color = _getColorFromHex(widget.subjectColor);

    Color statusColor;
    if (isCompleted) {
      statusColor = Colors.green;
    } else if (isOverdue) {
      statusColor = Colors.red;
    } else if (daysRemaining <= 2) {
      statusColor = Colors.orange;
    } else {
      statusColor = color;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCompleted ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Checkbox(
            value: isCompleted,
            onChanged: (_) => _toggleTaskCompletion(task),
            activeColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            task['title'],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    '${dueDate.day}.${dueDate.month}.${dueDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOverdue
                            ? 'Zamujeno'
                            : daysRemaining == 0
                                ? 'Danes'
                                : daysRemaining == 1
                                    ? 'Jutri'
                                    : '$daysRemaining dni',
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (task['description'] != null && task['description'].isNotEmpty)
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
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[500]),
            onSelected: (value) {
              if (value == 'edit') {
                _showAddEditTaskDialog(task: task);
              } else if (value == 'delete') {
                _deleteTask(task);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Uredi'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Izbriši', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab(bool isDark) {
    if (_isLoadingDecks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ni kompletov',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ustvarite svoj prvi komplet kartic',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        return _buildDeckCard(deck, isDark);
      },
    );
  }

  Widget _buildDeckCard(FlashcardDeck deck, bool isDark) {
    final color = _hexToColor(deck.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlashcardEditScreen(deck: deck),
            ),
          ).then((_) => _loadDecks());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.style, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        if (deck.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            deck.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Izbriši komplet?'),
                            content: Text('Ali res želiš izbrisati "${deck.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Prekliči'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Izbriši', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await _flashcardService.deleteDeck(deck.id!);
                          _loadDecks();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Izbriši', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.layers, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    '${deck.cardCount} kartic',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: deck.cardCount > 0
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FlashcardStudyScreen(deck: deck),
                              ),
                            ).then((_) => _loadDecks());
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Učenje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
