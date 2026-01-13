import 'package:sqflite/sqflite.dart';
import '../models/flashcard.dart';
import 'db_service.dart';

class FlashcardService {
  final DBService _dbService = DBService();

  // Ustvari tabele za flashcards (kliči ob prvem zagonu)
  Future<void> createTables() async {
    final db = await _dbService.database;
    
    // Preveri če tabela že obstaja
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='flashcard_decks'"
    );
    
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE flashcard_decks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT,
          name TEXT NOT NULL,
          description TEXT,
          color TEXT DEFAULT '#9C27B0',
          created_at TEXT DEFAULT (datetime('now'))
        )
      ''');

      await db.execute('''
        CREATE TABLE flashcards(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deck_id INTEGER NOT NULL,
          question TEXT NOT NULL,
          answer TEXT NOT NULL,
          repetitions INTEGER DEFAULT 0,
          ease_factor REAL DEFAULT 2.5,
          interval INTEGER DEFAULT 0,
          next_review TEXT,
          created_at TEXT DEFAULT (datetime('now')),
          FOREIGN KEY (deck_id) REFERENCES flashcard_decks(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // === DECK OPERACIJE ===
  
  Future<int> insertDeck(FlashcardDeck deck) async {
    final db = await _dbService.database;
    return await db.insert('flashcard_decks', {
      'name': deck.name,
      'description': deck.description,
      'color': deck.color,
    });
  }

  Future<List<FlashcardDeck>> getAllDecks() async {
    final db = await _dbService.database;
    final decks = await db.rawQuery('''
      SELECT d.*, COUNT(f.id) as card_count 
      FROM flashcard_decks d 
      LEFT JOIN flashcards f ON d.id = f.deck_id 
      GROUP BY d.id 
      ORDER BY d.created_at DESC
    ''');
    return decks.map((map) => FlashcardDeck.fromMap(map)).toList();
  }

  Future<FlashcardDeck?> getDeck(int id) async {
    final db = await _dbService.database;
    final result = await db.rawQuery('''
      SELECT d.*, COUNT(f.id) as card_count 
      FROM flashcard_decks d 
      LEFT JOIN flashcards f ON d.id = f.deck_id 
      WHERE d.id = ?
      GROUP BY d.id
    ''', [id]);
    
    if (result.isEmpty) return null;
    return FlashcardDeck.fromMap(result.first);
  }

  Future<int> updateDeck(int id, FlashcardDeck deck) async {
    final db = await _dbService.database;
    return await db.update(
      'flashcard_decks',
      {
        'name': deck.name,
        'description': deck.description,
        'color': deck.color,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDeck(int id) async {
    final db = await _dbService.database;
    // Najprej izbriši vse kartice v decku
    await db.delete('flashcards', where: 'deck_id = ?', whereArgs: [id]);
    // Potem izbriši deck
    return await db.delete('flashcard_decks', where: 'id = ?', whereArgs: [id]);
  }

  // === FLASHCARD OPERACIJE ===

  Future<int> insertFlashcard(Flashcard card) async {
    final db = await _dbService.database;
    return await db.insert('flashcards', {
      'deck_id': card.deckId,
      'question': card.question,
      'answer': card.answer,
      'repetitions': card.repetitions,
      'ease_factor': card.easeFactor,
      'interval': card.interval,
      'next_review': card.nextReview?.toIso8601String(),
    });
  }

  Future<List<Flashcard>> getFlashcardsForDeck(int deckId) async {
    final db = await _dbService.database;
    final cards = await db.query(
      'flashcards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'created_at DESC',
    );
    return cards.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getCardsForReview(int deckId) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    
    final cards = await db.query(
      'flashcards',
      where: 'deck_id = ? AND (next_review IS NULL OR next_review <= ?)',
      whereArgs: [deckId, now],
      orderBy: 'next_review ASC',
    );
    return cards.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<int> getCardsForReviewCount(int deckId) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM flashcards 
      WHERE deck_id = ? AND (next_review IS NULL OR next_review <= ?)
    ''', [deckId, now]);
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> updateFlashcard(Flashcard card) async {
    final db = await _dbService.database;
    return await db.update(
      'flashcards',
      {
        'question': card.question,
        'answer': card.answer,
        'repetitions': card.repetitions,
        'ease_factor': card.easeFactor,
        'interval': card.interval,
        'next_review': card.nextReview?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteFlashcard(int id) async {
    final db = await _dbService.database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  // Posodobi kartico po ogledu (SM-2 algoritem)
  Future<void> reviewCard(Flashcard card, int quality) async {
    final updatedCard = SM2Algorithm.calculate(card, quality);
    await updateFlashcard(updatedCard);
  }
}
