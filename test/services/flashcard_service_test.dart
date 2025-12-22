import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/flashcard.dart';

/// Tests for Flashcard service functionality using the Flashcard model
/// 
/// Note: FlashcardService uses a fixed FirebaseFirestore.instance internally,
/// so we test the model transformations and Flashcard status logic instead
/// of mocking the full service.
void main() {
  group('Flashcard Service Logic', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final reviewDate = DateTime(2024, 1, 20, 14, 0);

    Flashcard createTestFlashcard({
      String id = 'flashcard_1',
      String projectId = 'project_1',
      String status = 'unlearned',
      double masteryLevel = 0.0,
      bool isFavorite = false,
      List<String> tags = const ['test'],
      int reviewCount = 0,
    }) {
      return Flashcard(
        id: id,
        projectId: projectId,
        question: 'What is Flutter?',
        answer: 'A UI toolkit for building apps',
        difficulty: 'medium',
        tags: tags,
        reviewCount: reviewCount,
        masteryLevel: masteryLevel,
        status: status,
        isFavorite: isFavorite,
        createdAt: testDate,
      );
    }

    group('Status transitions (FR-8.5 & FR-8.6)', () {
      test('should transition from unlearned to mastered', () {
        final card = createTestFlashcard(status: 'unlearned');
        final updated = card.copyWith(status: 'mastered', masteryLevel: 1.0);

        expect(updated.status, 'mastered');
        expect(updated.masteryLevel, 1.0);
        expect(updated.question, card.question); // Other fields unchanged
      });

      test('should transition from unlearned to review', () {
        final card = createTestFlashcard(status: 'unlearned');
        final updated = card.copyWith(status: 'review', masteryLevel: 0.5);

        expect(updated.status, 'review');
        expect(updated.masteryLevel, 0.5);
      });

      test('should transition from review to difficult', () {
        final card = createTestFlashcard(status: 'review');
        final updated = card.copyWith(status: 'difficult', masteryLevel: 0.25);

        expect(updated.status, 'difficult');
        expect(updated.masteryLevel, 0.25);
      });

      test('should transition from difficult back to mastered', () {
        final card = createTestFlashcard(status: 'difficult');
        final updated = card.copyWith(status: 'mastered', masteryLevel: 1.0);

        expect(updated.status, 'mastered');
        expect(updated.masteryLevel, 1.0);
      });
    });

    group('Favorite toggle', () {
      test('should toggle favorite to true', () {
        final card = createTestFlashcard(isFavorite: false);
        final updated = card.copyWith(isFavorite: true);

        expect(updated.isFavorite, isTrue);
        expect(updated.status, card.status); // Other fields unchanged
      });

      test('should toggle favorite to false', () {
        final card = createTestFlashcard(isFavorite: true);
        final updated = card.copyWith(isFavorite: false);

        expect(updated.isFavorite, isFalse);
      });
    });

    group('Review count and mastery tracking', () {
      test('should increment review count', () {
        final card = createTestFlashcard(reviewCount: 0);
        final updated = card.copyWith(
          reviewCount: card.reviewCount + 1,
          lastReviewed: reviewDate,
        );

        expect(updated.reviewCount, 1);
        expect(updated.lastReviewed, reviewDate);
      });

      test('should track multiple reviews', () {
        var card = createTestFlashcard(reviewCount: 0);
        
        // Simulate multiple reviews
        for (int i = 0; i < 5; i++) {
          card = card.copyWith(reviewCount: card.reviewCount + 1);
        }

        expect(card.reviewCount, 5);
      });

      test('should update mastery level on review', () {
        final card = createTestFlashcard(masteryLevel: 0.0);
        
        // Simulate gradual mastery improvement
        var updated = card.copyWith(masteryLevel: 0.25);
        expect(updated.masteryLevel, 0.25);
        
        updated = updated.copyWith(masteryLevel: 0.5);
        expect(updated.masteryLevel, 0.5);
        
        updated = updated.copyWith(masteryLevel: 1.0);
        expect(updated.masteryLevel, 1.0);
      });
    });

    group('Tag operations (FR-8.8)', () {
      test('should create flashcard with multiple tags', () {
        final card = createTestFlashcard(tags: ['flutter', 'dart', 'mobile']);

        expect(card.tags.length, 3);
        expect(card.tags, containsAll(['flutter', 'dart', 'mobile']));
      });

      test('should create flashcard with empty tags', () {
        final card = createTestFlashcard(tags: []);

        expect(card.tags, isEmpty);
      });

      test('should update tags via copyWith', () {
        final card = createTestFlashcard(tags: ['old']);
        final updated = card.copyWith(tags: ['new1', 'new2']);

        expect(updated.tags, ['new1', 'new2']);
      });
    });

    group('Statistics calculation helpers (FR-9.3)', () {
      test('should categorize flashcards by status', () {
        final cards = [
          createTestFlashcard(id: 'f1', status: 'mastered'),
          createTestFlashcard(id: 'f2', status: 'mastered'),
          createTestFlashcard(id: 'f3', status: 'review'),
          createTestFlashcard(id: 'f4', status: 'difficult'),
          createTestFlashcard(id: 'f5', status: 'unlearned'),
        ];

        final stats = {
          'total': cards.length,
          'mastered': cards.where((c) => c.status == 'mastered').length,
          'review': cards.where((c) => c.status == 'review').length,
          'difficult': cards.where((c) => c.status == 'difficult').length,
          'unlearned': cards.where((c) => c.status == 'unlearned').length,
        };

        expect(stats['total'], 5);
        expect(stats['mastered'], 2);
        expect(stats['review'], 1);
        expect(stats['difficult'], 1);
        expect(stats['unlearned'], 1);
      });

      test('should calculate mastery percentage', () {
        final cards = [
          createTestFlashcard(id: 'f1', masteryLevel: 1.0),
          createTestFlashcard(id: 'f2', masteryLevel: 0.5),
          createTestFlashcard(id: 'f3', masteryLevel: 0.0),
        ];

        final avgMastery = cards.map((c) => c.masteryLevel).reduce((a, b) => a + b) / cards.length;

        expect(avgMastery, 0.5);
      });
    });

    group('Filtering by status (FR-8.9)', () {
      test('should filter mastered cards', () {
        final cards = [
          createTestFlashcard(id: 'f1', status: 'mastered'),
          createTestFlashcard(id: 'f2', status: 'review'),
          createTestFlashcard(id: 'f3', status: 'mastered'),
        ];

        final mastered = cards.where((c) => c.status == 'mastered').toList();

        expect(mastered.length, 2);
        expect(mastered.every((c) => c.status == 'mastered'), isTrue);
      });

      test('should filter review cards', () {
        final cards = [
          createTestFlashcard(id: 'f1', status: 'review'),
          createTestFlashcard(id: 'f2', status: 'mastered'),
        ];

        final review = cards.where((c) => c.status == 'review').toList();

        expect(review.length, 1);
        expect(review.first.status, 'review');
      });

      test('should filter difficult cards', () {
        final cards = [
          createTestFlashcard(id: 'f1', status: 'difficult'),
          createTestFlashcard(id: 'f2', status: 'difficult'),
          createTestFlashcard(id: 'f3', status: 'mastered'),
        ];

        final difficult = cards.where((c) => c.status == 'difficult').toList();

        expect(difficult.length, 2);
      });
    });

    group('Filtering by tag (FR-8.8)', () {
      test('should filter cards by single tag', () {
        final cards = [
          createTestFlashcard(id: 'f1', tags: ['flutter', 'dart']),
          createTestFlashcard(id: 'f2', tags: ['mobile']),
          createTestFlashcard(id: 'f3', tags: ['flutter', 'ui']),
        ];

        final flutterCards = cards.where((c) => c.tags.contains('flutter')).toList();

        expect(flutterCards.length, 2);
        expect(flutterCards.every((c) => c.tags.contains('flutter')), isTrue);
      });

      test('should get unique tags from all cards', () {
        final cards = [
          createTestFlashcard(id: 'f1', tags: ['flutter', 'dart']),
          createTestFlashcard(id: 'f2', tags: ['dart', 'mobile']),
          createTestFlashcard(id: 'f3', tags: ['flutter', 'ui']),
        ];

        final allTags = <String>{};
        for (final card in cards) {
          allTags.addAll(card.tags);
        }

        expect(allTags, containsAll(['flutter', 'dart', 'mobile', 'ui']));
        expect(allTags.length, 4); // No duplicates
      });
    });

    group('Difficulty levels', () {
      test('should accept easy difficulty', () {
        final card = Flashcard(
          id: 'f1',
          projectId: 'p1',
          question: 'Easy question',
          answer: 'Easy answer',
          difficulty: 'easy',
          tags: [],
          reviewCount: 0,
          masteryLevel: 0.0,
          status: 'unlearned',
          createdAt: testDate,
        );

        expect(card.difficulty, 'easy');
      });

      test('should accept hard difficulty', () {
        final card = Flashcard(
          id: 'f1',
          projectId: 'p1',
          question: 'Hard question',
          answer: 'Hard answer',
          difficulty: 'hard',
          tags: [],
          reviewCount: 0,
          masteryLevel: 0.0,
          status: 'unlearned',
          createdAt: testDate,
        );

        expect(card.difficulty, 'hard');
      });
    });

    group('Progress tracking (FR-8.7)', () {
      test('should count learned vs total cards', () {
        final cards = [
          createTestFlashcard(id: 'f1', status: 'mastered'),
          createTestFlashcard(id: 'f2', status: 'review'),
          createTestFlashcard(id: 'f3', status: 'unlearned'),
          createTestFlashcard(id: 'f4', status: 'mastered'),
          createTestFlashcard(id: 'f5', status: 'difficult'),
        ];

        final total = cards.length;
        final learned = cards.where((c) => c.status != 'unlearned').length;

        expect(total, 5);
        expect(learned, 4); // All except unlearned
      });
    });
  });
}
