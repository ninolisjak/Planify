import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import 'flashcard_study_screen.dart';
import 'flashcard_edit_screen.dart';

class FlashcardDecksScreen extends StatefulWidget {
  final int? subjectId;
  final String? subjectName;
  final String? subjectColor;

  const FlashcardDecksScreen({
    super.key,
    this.subjectId,
    this.subjectName,
    this.subjectColor,
  });

  @override
  State<FlashcardDecksScreen> createState() => _FlashcardDecksScreenState();
}

class _FlashcardDecksScreenState extends State<FlashcardDecksScreen> {
  final FlashcardService _service = FlashcardService();
  List<FlashcardDeck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _service.createTables();
    await _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() => _isLoading = true);
    final decks = await _service.getAllDecks(subjectId: widget.subjectId);
    setState(() {
      _decks = decks;
      _isLoading = false;
    });
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
                    hintText: 'npr. Angleščina',
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
                
                await _service.insertDeck(deck);
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

  void _showEditDeckDialog(FlashcardDeck deck) {
    final nameController = TextEditingController(text: deck.name);
    final descController = TextEditingController(text: deck.description ?? '');
    String selectedColor = deck.color;

    final colors = [
      '#9C27B0', '#E91E63', '#F44336', '#FF9800', 
      '#4CAF50', '#2196F3', '#3F51B5', '#607D8B',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Uredi komplet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ime kompleta',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Opis (opcijsko)',
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
                
                final updatedDeck = FlashcardDeck(
                  id: deck.id,
                  subjectId: deck.subjectId ?? widget.subjectId,
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty 
                      ? null 
                      : descController.text.trim(),
                  color: selectedColor,
                );
                
                await _service.updateDeck(deck.id!, updatedDeck);
                Navigator.pop(context);
                _loadDecks();
              },
              child: const Text('Shrani'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDeck(FlashcardDeck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izbriši komplet?'),
        content: Text('Ali res želiš izbrisati "${deck.name}" in vse kartice v njem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Prekliči'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteDeck(deck.id!);
              Navigator.pop(context);
              _loadDecks();
            },
            child: const Text('Izbriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.subjectName != null 
            ? 'Flashcards - ${widget.subjectName}' 
            : 'Flashcards'),
        backgroundColor: widget.subjectColor != null 
            ? _hexToColor(widget.subjectColor!)
            : Colors.transparent,
        elevation: widget.subjectColor != null ? 2 : 0,
        foregroundColor: widget.subjectColor != null 
            ? Colors.white 
            : (isDark ? Colors.white : Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _decks.isEmpty
              ? _buildEmptyState(isDark)
              : _buildDeckList(isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDeckDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nov komplet'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Ni kompletov',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ustvari svoj prvi komplet kartic!',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        return _DeckCard(
          deck: deck,
          isDark: isDark,
          onTap: () => _openDeck(deck),
          onEdit: () => _showEditDeckDialog(deck),
          onDelete: () => _confirmDeleteDeck(deck),
          onStudy: () => _studyDeck(deck),
        );
      },
    );
  }

  void _openDeck(FlashcardDeck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardEditScreen(deck: deck),
      ),
    ).then((_) => _loadDecks());
  }

  void _studyDeck(FlashcardDeck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardStudyScreen(deck: deck),
      ),
    ).then((_) => _loadDecks());
  }
}

class _DeckCard extends StatelessWidget {
  final FlashcardDeck deck;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStudy;

  const _DeckCard({
    required this.deck,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStudy,
  });

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(deck.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
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
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
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
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.layers,
                    label: '${deck.cardCount} kartic',
                    isDark: isDark,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: deck.cardCount > 0 ? onStudy : null,
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black45),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
