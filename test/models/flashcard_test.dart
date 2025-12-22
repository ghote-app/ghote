import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/flashcard.dart';

void main() {
  group('Flashcard Model', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final reviewDate = DateTime(2024, 1, 20, 14, 0);

    test('should create Flashcard with required parameters', () {
      final flashcard = Flashcard(
        id: 'card_1',
        projectId: 'project_1',
        question: 'What is Flutter?',
        answer: 'A UI toolkit for building natively compiled applications',
        createdAt: testDate,
      );

      expect(flashcard.id, 'card_1');
      expect(flashcard.projectId, 'project_1');
      expect(flashcard.question, 'What is Flutter?');
      expect(flashcard.answer, 'A UI toolkit for building natively compiled applications');
      expect(flashcard.difficulty, 'medium'); // default
      expect(flashcard.tags, isEmpty); // default
      expect(flashcard.reviewCount, 0); // default
      expect(flashcard.masteryLevel, 0.0); // default
      expect(flashcard.status, 'unlearned'); // default
    });

    test('should use default values for optional parameters', () {
      final flashcard = Flashcard(
        id: 'card_1',
        projectId: 'project_1',
        question: 'Question',
        answer: 'Answer',
        createdAt: testDate,
      );

      expect(flashcard.fileId, isNull);
      expect(flashcard.difficulty, 'medium');
      expect(flashcard.tags, isEmpty);
      expect(flashcard.lastReviewed, isNull);
      expect(flashcard.reviewCount, 0);
      expect(flashcard.masteryLevel, 0.0);
      expect(flashcard.isFavorite, false);
      expect(flashcard.status, 'unlearned');
    });

    group('difficultyLabel', () {
      test('should return 簡單 for easy', () {
        final card = Flashcard(
          id: '1',
          projectId: '1',
          question: 'Q',
          answer: 'A',
          difficulty: 'easy',
          createdAt: testDate,
        );
        expect(card.difficultyLabel, '簡單');
      });

      test('should return 中等 for medium', () {
        final card = Flashcard(
          id: '1',
          projectId: '1',
          question: 'Q',
          answer: 'A',
          difficulty: 'medium',
          createdAt: testDate,
        );
        expect(card.difficultyLabel, '中等');
      });

      test('should return 困難 for hard', () {
        final card = Flashcard(
          id: '1',
          projectId: '1',
          question: 'Q',
          answer: 'A',
          difficulty: 'hard',
          createdAt: testDate,
        );
        expect(card.difficultyLabel, '困難');
      });
    });

    group('statusLabel', () {
      test('should return correct status labels', () {
        expect(
          Flashcard(id: '1', projectId: '1', question: 'Q', answer: 'A', createdAt: testDate, status: 'mastered').statusLabel,
          '已掌握',
        );
        expect(
          Flashcard(id: '1', projectId: '1', question: 'Q', answer: 'A', createdAt: testDate, status: 'review').statusLabel,
          '需複習',
        );
        expect(
          Flashcard(id: '1', projectId: '1', question: 'Q', answer: 'A', createdAt: testDate, status: 'difficult').statusLabel,
          '困難',
        );
        expect(
          Flashcard(id: '1', projectId: '1', question: 'Q', answer: 'A', createdAt: testDate, status: 'unlearned').statusLabel,
          '未學習',
        );
      });
    });

    group('getStatusColor', () {
      test('should return correct colors for each status', () {
        expect(Flashcard.getStatusColor('mastered'), 0xFF4CAF50); // Green
        expect(Flashcard.getStatusColor('review'), 0xFFFF9800); // Orange
        expect(Flashcard.getStatusColor('difficult'), 0xFFF44336); // Red
        expect(Flashcard.getStatusColor('unlearned'), 0xFF9E9E9E); // Grey
        expect(Flashcard.getStatusColor('unknown'), 0xFF9E9E9E); // Default Grey
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = Flashcard(
          id: 'card_1',
          projectId: 'project_1',
          question: 'Original Question',
          answer: 'Original Answer',
          createdAt: testDate,
        );

        final copied = original.copyWith(
          question: 'Updated Question',
          difficulty: 'hard',
          masteryLevel: 0.8,
          status: 'mastered',
        );

        expect(copied.question, 'Updated Question');
        expect(copied.difficulty, 'hard');
        expect(copied.masteryLevel, 0.8);
        expect(copied.status, 'mastered');
        // Original values preserved
        expect(copied.id, 'card_1');
        expect(copied.projectId, 'project_1');
        expect(copied.answer, 'Original Answer');
      });

      test('should preserve original values when not specified', () {
        final original = Flashcard(
          id: 'card_1',
          projectId: 'project_1',
          question: 'Q',
          answer: 'A',
          difficulty: 'hard',
          masteryLevel: 0.5,
          createdAt: testDate,
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.difficulty, original.difficulty);
        expect(copied.masteryLevel, original.masteryLevel);
      });
    });

    group('JSON serialization', () {
      test('toJson should convert Flashcard to Map', () {
        final flashcard = Flashcard(
          id: 'card_1',
          projectId: 'project_1',
          fileId: 'file_1',
          question: 'What is Flutter?',
          answer: 'A UI toolkit',
          difficulty: 'hard',
          tags: ['flutter', 'dart'],
          createdAt: testDate,
          lastReviewed: reviewDate,
          reviewCount: 5,
          masteryLevel: 0.8,
          isFavorite: true,
          status: 'mastered',
        );

        final json = flashcard.toJson();

        expect(json['id'], 'card_1');
        expect(json['projectId'], 'project_1');
        expect(json['fileId'], 'file_1');
        expect(json['question'], 'What is Flutter?');
        expect(json['answer'], 'A UI toolkit');
        expect(json['difficulty'], 'hard');
        expect(json['tags'], ['flutter', 'dart']);
        expect(json['createdAt'], testDate.toIso8601String());
        expect(json['lastReviewed'], reviewDate.toIso8601String());
        expect(json['reviewCount'], 5);
        expect(json['masteryLevel'], 0.8);
        expect(json['isFavorite'], true);
        expect(json['status'], 'mastered');
      });

      test('fromJson should create Flashcard from Map', () {
        final json = {
          'id': 'card_1',
          'projectId': 'project_1',
          'fileId': 'file_1',
          'question': 'What is Flutter?',
          'answer': 'A UI toolkit',
          'difficulty': 'hard',
          'tags': ['flutter', 'dart'],
          'createdAt': testDate.toIso8601String(),
          'lastReviewed': reviewDate.toIso8601String(),
          'reviewCount': 5,
          'masteryLevel': 0.8,
          'isFavorite': true,
          'status': 'mastered',
        };

        final flashcard = Flashcard.fromJson(json);

        expect(flashcard.id, 'card_1');
        expect(flashcard.projectId, 'project_1');
        expect(flashcard.fileId, 'file_1');
        expect(flashcard.question, 'What is Flutter?');
        expect(flashcard.answer, 'A UI toolkit');
        expect(flashcard.difficulty, 'hard');
        expect(flashcard.tags, ['flutter', 'dart']);
        expect(flashcard.createdAt, testDate);
        expect(flashcard.lastReviewed, reviewDate);
        expect(flashcard.reviewCount, 5);
        expect(flashcard.masteryLevel, 0.8);
        expect(flashcard.isFavorite, true);
        expect(flashcard.status, 'mastered');
      });

      test('fromJson should use default values for optional fields', () {
        final json = {
          'id': 'card_1',
          'projectId': 'project_1',
          'question': 'Q',
          'answer': 'A',
          'createdAt': testDate.toIso8601String(),
        };

        final flashcard = Flashcard.fromJson(json);

        expect(flashcard.fileId, isNull);
        expect(flashcard.difficulty, 'medium');
        expect(flashcard.tags, isEmpty);
        expect(flashcard.lastReviewed, isNull);
        expect(flashcard.reviewCount, 0);
        expect(flashcard.masteryLevel, 0.0);
        expect(flashcard.isFavorite, false);
        expect(flashcard.status, 'unlearned');
      });

      test('JSON round trip should preserve all data', () {
        final original = Flashcard(
          id: 'card_1',
          projectId: 'project_1',
          fileId: 'file_1',
          question: 'What is Flutter?',
          answer: 'A UI toolkit',
          difficulty: 'hard',
          tags: ['flutter', 'dart'],
          createdAt: testDate,
          lastReviewed: reviewDate,
          reviewCount: 5,
          masteryLevel: 0.8,
          isFavorite: true,
          status: 'mastered',
        );

        final json = original.toJson();
        final restored = Flashcard.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.projectId, original.projectId);
        expect(restored.fileId, original.fileId);
        expect(restored.question, original.question);
        expect(restored.answer, original.answer);
        expect(restored.difficulty, original.difficulty);
        expect(restored.tags, original.tags);
        expect(restored.createdAt, original.createdAt);
        expect(restored.lastReviewed, original.lastReviewed);
        expect(restored.reviewCount, original.reviewCount);
        expect(restored.masteryLevel, original.masteryLevel);
        expect(restored.isFavorite, original.isFavorite);
        expect(restored.status, original.status);
      });
    });
  });
}
