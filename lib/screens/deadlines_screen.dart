import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/calendar_service.dart';
import '../models/exam_deadline.dart';

class DeadlinesScreen extends StatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen> {
  final DBService _dbService = DBService();
  final CalendarService _calendarService = CalendarService();
  List<ExamDeadline> _deadlines = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  bool _calendarConnected = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _dbService.createExamDeadlinesTable();
    _calendarConnected = await _calendarService.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final deadlinesData = await _dbService.getAllExamDeadlines();
      final subjectsData = await _dbService.getAllSubjects();
      setState(() {
        _deadlines = deadlinesData.map((e) => ExamDeadline.fromMap(e)).toList();
        _subjects = subjectsData;
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

  Future<void> _showAddEditDialog({ExamDeadline? deadline}) async {
    final isEditing = deadline != null;
    final subjectController = TextEditingController(
      text: deadline?.subjectName ?? '',
    );
    int? selectedSubjectId = deadline?.subjectId;
    DateTime selectedDate = deadline?.examDate ?? DateTime.now().add(const Duration(days: 7));
    TimeOfDay? selectedTime;
    
    if (deadline?.examTime != null) {
      final parts = deadline!.examTime!.split(':');
      if (parts.length == 2) {
        selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    
    final durationController = TextEditingController(
      text: deadline?.durationMinutes?.toString() ?? '',
    );
    final locationController = TextEditingController(
      text: deadline?.location ?? '',
    );
    final notesController = TextEditingController(
      text: deadline?.notes ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Uredi rok' : 'Dodaj izpitni rok'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Izbira predmeta
                if (_subjects.isNotEmpty) ...[
                  const Text(
                    'Izberi predmet:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: selectedSubjectId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Izberi predmet'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Brez predmeta'),
                      ),
                      ..._subjects.map((s) => DropdownMenuItem<int?>(
                        value: s['id'] as int,
                        child: Text(s['name'] as String),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedSubjectId = value;
                        if (value != null) {
                          final subject = _subjects.firstWhere((s) => s['id'] == value);
                          subjectController.text = subject['name'] as String;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Ime predmeta (ročno)
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Ime predmeta *',
                    hintText: 'npr. Matematika',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                
                // Datum
                const Text(
                  'Datum izpita: *',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
                
                // Čas
                const Text(
                  'Čas pisanja:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
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
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          selectedTime != null
                              ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Izberi čas',
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedTime != null ? null : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        if (selectedTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setDialogState(() => selectedTime = null);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Trajanje
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Trajanje (minute)',
                    hintText: 'npr. 90',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Lokacija
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokacija',
                    hintText: 'npr. P1, Predavalnica 101',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Opombe
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Opombe',
                    hintText: 'Dodatne informacije...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                final subjectName = subjectController.text.trim();

                if (subjectName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ime predmeta je obvezno')),
                  );
                  return;
                }

                final data = {
                  'subject_id': selectedSubjectId,
                  'subject_name': subjectName,
                  'exam_date': selectedDate.toIso8601String(),
                  'exam_time': selectedTime != null
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                      : null,
                  'duration_minutes': durationController.text.isNotEmpty
                      ? int.tryParse(durationController.text)
                      : null,
                  'location': locationController.text.trim().isNotEmpty
                      ? locationController.text.trim()
                      : null,
                  'notes': notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                };

                try {
                  int? deadlineId;
                  if (isEditing) {
                    await _dbService.updateExamDeadline(deadline.id!, data);
                    deadlineId = deadline.id;
                  } else {
                    deadlineId = await _dbService.insertExamDeadline(data);
                  }

                  // Sinhronizacija z Google Calendar
                  if (_calendarConnected && deadlineId != null) {
                    DateTime eventDateTime = selectedDate;
                    if (selectedTime != null) {
                      eventDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                    }
                    
                    final eventId = await _calendarService.addDeadlineToCalendar(
                      title: 'Izpit',
                      subjectName: subjectName,
                      dateTime: eventDateTime,
                      description: '${locationController.text.isNotEmpty ? "Lokacija: ${locationController.text}\n" : ""}${notesController.text}',
                    );
                    
                    if (eventId != null) {
                      // Shrani povezavo v bazo
                      await _dbService.saveSyncStatus(deadlineId, eventId, 'deadline');
                    }
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Rok posodobljen${_calendarConnected ? " in sinhroniziran" : ""}'
                            : 'Rok dodan${_calendarConnected ? " in dodan v Google Calendar" : ""}'),
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

  Future<void> _deleteDeadline(ExamDeadline deadline) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izbriši rok'),
        content: Text('Ali ste prepričani, da želite izbrisati rok za "${deadline.subjectName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
          final eventId = await _dbService.getGoogleEventId(deadline.id!, 'deadline');
          if (eventId != null) {
            await _calendarService.deleteCalendarEvent(eventId);
            await _dbService.deleteSyncStatus(deadline.id!, 'deadline');
          }
        }
        
        await _dbService.deleteExamDeadline(deadline.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_calendarConnected 
                ? 'Rok izbrisan iz aplikacije in koledarja' 
                : 'Rok izbrisan')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Napaka pri brisanju: $e')),
          );
        }
      }
    }
  }

  Color _getDeadlineColor(ExamDeadline deadline) {
    final daysRemaining = deadline.daysRemaining;
    if (deadline.isPast) return Colors.grey;
    if (daysRemaining <= 3) return Colors.red;
    if (daysRemaining <= 7) return Colors.orange;
    if (daysRemaining <= 14) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Izpitni roki'),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E24AA),
                Color(0xFFEC407A),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deadlines.isEmpty
              ? _buildEmptyState()
              : _buildDeadlinesList(isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj rok'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ni izpitnih rokov',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodajte svoj prvi izpitni rok s pritiskom na gumb spodaj',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesList(bool isDark) {
    // Razdelimo na prihajajoče in pretekle
    final upcoming = _deadlines.where((d) => !d.isPast).toList();
    final past = _deadlines.where((d) => d.isPast).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Prihajajoči roki',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...upcoming.map((deadline) => _buildDeadlineCard(deadline, isDark)),
        ],
        if (past.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Text(
              'Pretekli roki',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          ...past.map((deadline) => _buildDeadlineCard(deadline, isDark, isPast: true)),
        ],
      ],
    );
  }

  Widget _buildDeadlineCard(ExamDeadline deadline, bool isDark, {bool isPast = false}) {
    final color = _getDeadlineColor(deadline);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPast ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Opacity(
        opacity: isPast ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            deadline.examDate.day.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _getMonthShort(deadline.examDate.month),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deadline.subjectName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                deadline.examTime ?? 'Čas ni določen',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              if (deadline.durationMinutes != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${deadline.durationMinutes} min',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isPast)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          deadline.daysRemaining == 0
                              ? 'DANES'
                              : deadline.daysRemaining == 1
                                  ? 'JUTRI'
                                  : '${deadline.daysRemaining} dni',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showAddEditDialog(deadline: deadline);
                            break;
                          case 'delete':
                            _deleteDeadline(deadline);
                            break;
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
                  ],
                ),
                if (deadline.location != null || deadline.notes != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (deadline.location != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            deadline.location!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (deadline.notes != null) ...[
                    if (deadline.location != null) const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            deadline.notes!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthShort(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAJ', 'JUN',
      'JUL', 'AVG', 'SEP', 'OKT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}
