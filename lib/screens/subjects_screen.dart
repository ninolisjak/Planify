import 'package:flutter/material.dart';
import '../services/db_service.dart';
import 'flashcard_decks_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final DBService _dbService = DBService();
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  // Preddefinirane barve za predmete
  final List<Color> _availableColors = [
    const Color(0xFF8E24AA), // Vijolična
    const Color(0xFFEC407A), // Roza
    const Color(0xFF42A5F5), // Modra
    const Color(0xFF66BB6A), // Zelena
    const Color(0xFFFFA726), // Oranžna
    const Color(0xFFEF5350), // Rdeča
    const Color(0xFF26C6DA), // Cyan
    const Color(0xFF7E57C2), // Temno vijolična
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFFFFCA28), // Rumena
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dbService.getAllSubjects();
      setState(() {
        _subjects = data;
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

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return _availableColors[0];
    }
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return _availableColors[0];
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? subject}) async {
    final isEditing = subject != null;
    final nameController = TextEditingController(text: subject?['name'] ?? '');
    final professorController = TextEditingController(text: subject?['professor'] ?? '');
    Color selectedColor = _getColorFromHex(subject?['color']);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Uredi predmet' : 'Dodaj predmet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ime predmeta',
                    hintText: 'npr. Matematika',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: professorController,
                  decoration: const InputDecoration(
                    labelText: 'Profesor',
                    hintText: 'npr. Prof. dr. Janez Novak',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Barva predmeta:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
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
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final professor = professorController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ime predmeta je obvezno')),
                  );
                  return;
                }

                final data = {
                  'name': name,
                  'professor': professor,
                  'color': _colorToHex(selectedColor),
                };

                try {
                  if (isEditing) {
                    await _dbService.updateSubject(subject['id'], data);
                  } else {
                    await _dbService.insertSubject(data);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadSubjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Predmet posodobljen'
                            : 'Predmet dodan'),
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

  Future<void> _deleteSubject(Map<String, dynamic> subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izbriši predmet'),
        content: Text('Ali ste prepričani, da želite izbrisati predmet "${subject['name']}"?'),
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
        await _dbService.deleteSubject(subject['id']);
        _loadSubjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Predmet izbrisan')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Predmeti'),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? _buildEmptyState()
              : _buildSubjectsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj predmet'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ni predmetov',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodajte svoj prvi predmet s pritiskom na gumb spodaj',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final color = _getColorFromHex(subject['color']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Odpri flashcard sistem za ta predmet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlashcardDecksScreen(
                    subjectId: subject['id'],
                    subjectName: subject['name'],
                    subjectColor: subject['color'],
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  subject['name'] ?? 'Brez imena',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  subject['professor']?.isNotEmpty == true
                      ? subject['professor']
                      : 'Ni profesorja',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showAddEditDialog(subject: subject);
                        break;
                      case 'delete':
                        _deleteSubject(subject);
                        break;
                      case 'flashcards':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlashcardDecksScreen(
                              subjectId: subject['id'],
                              subjectName: subject['name'],
                              subjectColor: subject['color'],
                            ),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'flashcards',
                      child: Row(
                        children: [
                          Icon(Icons.school, size: 20),
                          SizedBox(width: 8),
                          Text('Flashcards'),
                        ],
                      ),
                    ),
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
          ),
        );
      },
    );
  }
}
