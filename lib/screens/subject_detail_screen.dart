import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/db_service.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';
import 'task_detail_screen.dart';

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
  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  List<Map<String, dynamic>> _tasks = [];
  List<File> _materials = [];
  bool _isLoadingTasks = true;
  bool _isLoadingMaterials = true;
  bool _calendarConnected = false;

  @override
  void initState() {
    super.initState();
    _initCalendar();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _initCalendar() async {
    _calendarConnected = await _calendarService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTasks(),
      _loadMaterials(),
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

  Future<Directory> _getMaterialsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final materialsDir = Directory('${appDir.path}/gradivo/${widget.subjectId}');
    if (!await materialsDir.exists()) {
      await materialsDir.create(recursive: true);
    }
    return materialsDir;
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoadingMaterials = true);
    try {
      final dir = await _getMaterialsDirectory();
      final files = dir.listSync().whereType<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      setState(() {
        _materials = files;
        _isLoadingMaterials = false;
      });
    } catch (e) {
      setState(() => _isLoadingMaterials = false);
    }
  }

  Future<void> _addMaterial({bool fromCamera = false}) async {
    try {
      final XFile? image = fromCamera
          ? await _imagePicker.pickImage(source: ImageSource.camera)
          : await _imagePicker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      final dir = await _getMaterialsDirectory();
      final fileName = 'gradivo_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final savedFile = await File(image.path).copy('${dir.path}/$fileName');
      
      setState(() {
        _materials.insert(0, savedFile);
      });

      // Dodaj obvestilo za novo gradivo
      await _notificationService.notifyMaterialAdded(widget.subjectName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gradivo dodano')),
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

  Future<void> _deleteMaterial(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izbriši gradivo'),
        content: const Text('Ali ste prepričani, da želite izbrisati to sliko?'),
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
        await file.delete();
        _loadMaterials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gradivo izbrisano')),
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

  void _showMaterialOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotografiraj'),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Izberi iz galerije'),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
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
                  int? taskId;
                  if (isEditing) {
                    await _dbService.updateTask(task['id'], data);
                    taskId = task['id'];
                  } else {
                    taskId = await _dbService.insertTask(data);
                  }

                  // Sinhronizacija z Google Calendar
                  if (_calendarConnected && taskId != null && !isEditing) {
                    final eventId = await _calendarService.addTaskToCalendar(
                      taskTitle: title,
                      subjectName: widget.subjectName,
                      dueDate: selectedDate,
                      description: descriptionController.text.trim(),
                    );
                    
                    if (eventId != null) {
                      await _dbService.saveSyncStatus(taskId, eventId, 'task');
                    }
                  }

                  // Dodaj obvestilo za novo nalogo
                  if (!isEditing) {
                    await _notificationService.notifyTaskAdded(
                      title,
                      widget.subjectName,
                      selectedDate,
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadTasks();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing 
                            ? 'Naloga posodobljena' 
                            : 'Naloga dodana${_calendarConnected ? " in sinhronizirana" : ""}'),
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
        // Izbriši iz Google Calendar če obstaja
        if (_calendarConnected) {
          final eventId = await _dbService.getGoogleEventId(task['id'], 'task');
          if (eventId != null) {
            await _calendarService.deleteCalendarEvent(eventId);
            await _dbService.deleteSyncStatus(task['id'], 'task');
          }
        }
        
        await _dbService.deleteTask(task['id']);
        _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_calendarConnected 
                ? 'Naloga izbrisana iz aplikacije in koledarja' 
                : 'Naloga izbrisana')),
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
            Tab(icon: Icon(Icons.photo_library), text: 'Gradivo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksTab(isDark),
          _buildMaterialsTab(isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditTaskDialog();
          } else {
            _showMaterialOptions();
          }
        },
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return Text(_tabController.index == 0 ? 'Dodaj nalogo' : 'Dodaj gradivo');
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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskDetailScreen(
                  taskId: task['id'],
                  subjectName: widget.subjectName,
                  subjectColor: widget.subjectColor ?? '#8E24AA',
                ),
              ),
            );
            // Če je bila naloga izbrisana ali spremenjena, osveži seznam
            if (result == true) {
              _loadTasks();
            }
          },
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

  Widget _buildMaterialsTab(bool isDark) {
    if (_isLoadingMaterials) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ni gradiva',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dodajte slike zapiskov, screenshotov...',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final file = _materials[index];
        return _buildMaterialCard(file, isDark);
      },
    );
  }

  Widget _buildMaterialCard(File file, bool isDark) {
    final color = _getColorFromHex(widget.subjectColor);
    final fileName = path.basename(file.path);
    final modifiedDate = file.lastModifiedSync();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFullScreenImage(file),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () => _deleteMaterial(file),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Text(
                  '${modifiedDate.day}.${modifiedDate.month}.${modifiedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Gradivo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteMaterial(file);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(file),
            ),
          ),
        ),
      ),
    );
  }
}
