import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final FlashcardDeck deck;

  const FlashcardStudyScreen({super.key, required this.deck});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  final FlashcardService _service = FlashcardService();
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;
  bool _isFinished = false;

  // Statistika seje
  int _reviewed = 0;
  int _correct = 0;
  int _incorrect = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    
    // Najprej poskusi dobiti kartice za pregled
    var cards = await _service.getCardsForReview(widget.deck.id!);
    
    // Če ni kartic za pregled, vzemi vse
    if (cards.isEmpty) {
      cards = await _service.getFlashcardsForDeck(widget.deck.id!);
    }
    
    // Premešaj kartice
    cards.shuffle();
    
    setState(() {
      _cards = cards;
      _isLoading = false;
      _isFinished = cards.isEmpty;
    });
  }

  void _showCard() {
    setState(() => _showAnswer = true);
  }

  Future<void> _rateCard(int quality) async {
    if (_currentIndex >= _cards.length) return;

    final card = _cards[_currentIndex];
    await _service.reviewCard(card, quality);

    setState(() {
      _reviewed++;
      if (quality >= 3) {
        _correct++;
      } else {
        _incorrect++;
      }

      _showAnswer = false;
      _currentIndex++;

      if (_currentIndex >= _cards.length) {
        _isFinished = true;
      }
    });
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(widget.deck.name),
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isFinished) {
      return _buildFinishedScreen(isDark, color);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.deck.name),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${_cards.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Napredek
          LinearProgressIndicator(
            value: _cards.isEmpty ? 0 : (_currentIndex) / _cards.length,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            color: color,
          ),
          
          // Kartica
          Expanded(
            child: GestureDetector(
              onTap: _showAnswer ? null : _showCard,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: _buildFlashcard(isDark),
              ),
            ),
          ),

          // Gumbi za ocenjevanje
          if (_showAnswer) _buildRatingButtons(color),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFlashcard(bool isDark) {
    final card = _cards[_currentIndex];

    return Card(
      elevation: 8,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Oznaka
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _showAnswer ? 'ODGOVOR' : 'VPRAŠANJE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.black54,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Vsebina
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    _showAnswer ? card.answer : card.question,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Navodilo
            if (!_showAnswer) ...[
              const SizedBox(height: 16),
              Text(
                'Tapni za prikaz odgovora',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButtons(Color deckColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Kako težko je bilo?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RatingButton(
                  label: 'Ponovno',
                  sublabel: '<1min',
                  color: Colors.red,
                  onTap: () => _rateCard(0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RatingButton(
                  label: 'Težko',
                  sublabel: '<6min',
                  color: Colors.orange,
                  onTap: () => _rateCard(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RatingButton(
                  label: 'Dobro',
                  sublabel: '<10min',
                  color: Colors.green,
                  onTap: () => _rateCard(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RatingButton(
                  label: 'Lahko',
                  sublabel: '4dni',
                  color: Colors.blue,
                  onTap: () => _rateCard(5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedScreen(bool isDark, Color color) {
    final percentage = _reviewed > 0 ? (_correct / _reviewed * 100).round() : 0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Seja končana'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                'Odlično!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Končal si vse kartice v tem kompletu.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Statistika
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Pregledanih kartic',
                      value: '$_reviewed',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Pravilnih',
                      value: '$_correct',
                      valueColor: Colors.green,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Za ponovitev',
                      value: '$_incorrect',
                      valueColor: Colors.red,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _StatRow(
                      label: 'Uspešnost',
                      value: '$percentage%',
                      valueColor: color,
                      isDark: isDark,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _showAnswer = false;
                        _isFinished = false;
                        _reviewed = 0;
                        _correct = 0;
                        _incorrect = 0;
                      });
                      _loadCards();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ponovno'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Končaj'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
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

class _RatingButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool isBold;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}
