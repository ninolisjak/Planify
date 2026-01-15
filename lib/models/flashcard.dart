class Flashcard {
  final int? id;
  final int deckId;
  final String question;
  final String answer;
  final int repetitions;     // Število ponovitev
  final double easeFactor;   // Faktor lahkotnosti (Anki algoritem)
  final int interval;        // Interval v dnevih do naslednjega pregleda
  final DateTime? nextReview;
  final DateTime createdAt;

  Flashcard({
    this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.nextReview,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'question': question,
      'answer': answer,
      'repetitions': repetitions,
      'ease_factor': easeFactor,
      'interval': interval,
      'next_review': nextReview?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      deckId: map['deck_id'],
      question: map['question'],
      answer: map['answer'],
      repetitions: map['repetitions'] ?? 0,
      easeFactor: (map['ease_factor'] ?? 2.5).toDouble(),
      interval: map['interval'] ?? 0,
      nextReview: map['next_review'] != null 
          ? DateTime.parse(map['next_review']) 
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  Flashcard copyWith({
    int? id,
    int? deckId,
    String? question,
    String? answer,
    int? repetitions,
    double? easeFactor,
    int? interval,
    DateTime? nextReview,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      nextReview: nextReview ?? this.nextReview,
      createdAt: createdAt,
    );
  }
}

class FlashcardDeck {
  final int? id;
  final int? subjectId;
  final String name;
  final String? description;
  final String color;
  final DateTime createdAt;
  int cardCount;

  FlashcardDeck({
    this.id,
    this.subjectId,
    required this.name,
    this.description,
    this.color = '#9C27B0',
    DateTime? createdAt,
    this.cardCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'name': name,
      'description': description,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FlashcardDeck.fromMap(Map<String, dynamic> map) {
    return FlashcardDeck(
      id: map['id'],
      subjectId: map['subject_id'],
      name: map['name'],
      description: map['description'],
      color: map['color'] ?? '#9C27B0',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      cardCount: map['card_count'] ?? 0,
    );
  }
}

// Anki SM-2 algoritem za izračun naslednjega pregleda
class SM2Algorithm {
  // quality: 0-5 (0 = napačno, 5 = perfektno)
  static Flashcard calculate(Flashcard card, int quality) {
    double easeFactor = card.easeFactor;
    int repetitions = card.repetitions;
    int interval = card.interval;

    if (quality >= 3) {
      // Pravilen odgovor
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions++;
    } else {
      // Napačen odgovor - ponastavi
      repetitions = 0;
      interval = 1;
    }

    // Posodobi ease factor
    easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    final nextReview = DateTime.now().add(Duration(days: interval));

    return card.copyWith(
      repetitions: repetitions,
      easeFactor: easeFactor,
      interval: interval,
      nextReview: nextReview,
    );
  }
}
