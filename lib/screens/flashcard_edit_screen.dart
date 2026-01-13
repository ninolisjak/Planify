import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

class FlashcardEditScreen extends StatefulWidget {
  final FlashcardDeck deck;

  const FlashcardEditScreen({super.key, required this.deck});

  @override
  State<FlashcardEditScreen> createState() => _FlashcardEditScreenState();
}

class _FlashcardEditScreenState extends State<FlashcardEditScreen> {
  final FlashcardService _service = FlashcardService();
  List<Flashcard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await _service.getFlashcardsForDeck(widget.deck.id!);
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  void _showAddCardDialog() {
    final questionController = TextEditingController();
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova kartica'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Vprašanje / Sprednja stran',
                  hintText: 'npr. What is "hello" in Slovene?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Odgovor / Zadnja stran',
                  hintText: 'npr. Živjo',
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
          ElevatedButton(
            onPressed: () async {
              if (questionController.text.trim().isEmpty ||
                  answerController.text.trim().isEmpty) {
                return;
              }

              final card = Flashcard(
                deckId: widget.deck.id!,
                question: questionController.text.trim(),
                answer: answerController.text.trim(),
              );

              await _service.insertFlashcard(card);
              Navigator.pop(context);
              _loadCards();
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  void _showEditCardDialog(Flashcard card) {
    final questionController = TextEditingController(text: card.question);
    final answerController = TextEditingController(text: card.answer);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uredi kartico'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Vprašanje / Sprednja stran',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Odgovor / Zadnja stran',
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
          ElevatedButton(
            onPressed: () async {
              if (questionController.text.trim().isEmpty ||
                  answerController.text.trim().isEmpty) {
                return;
              }

              final updatedCard = card.copyWith(
                question: questionController.text.trim(),
                answer: answerController.text.trim(),
              );

              await _service.updateFlashcard(updatedCard);
              Navigator.pop(context);
              _loadCards();
            },
            child: const Text('Shrani'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCard(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izbriši kartico?'),
        content: const Text('Ali res želiš izbrisati to kartico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Prekliči'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteFlashcard(card.id!);
              Navigator.pop(context);
              _loadCards();
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
    final color = _hexToColor(widget.deck.color);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.deck.name),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCardDialog,
            tooltip: 'Dodaj kartico',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState(isDark)
              : _buildCardList(isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Ni kartic',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodaj svojo prvo kartico!',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj kartico'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _FlashcardItem(
          card: card,
          index: index + 1,
          isDark: isDark,
          onEdit: () => _showEditCardDialog(card),
          onDelete: () => _confirmDeleteCard(card),
        );
      },
    );
  }
}

class _FlashcardItem extends StatelessWidget {
  final Flashcard card;
  final int index;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlashcardItem({
    required this.card,
    required this.index,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Statistika učenja
                  if (card.repetitions > 0) ...[
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${card.repetitions}x',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Vprašanje
              Text(
                'V: ${card.question}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Odgovor
              Text(
                'O: ${card.answer}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
