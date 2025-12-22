import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/learning_progress.dart';

void main() {
  group('LearningProgress Model', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    test('should create LearningProgress with required parameters', () {
      final progress = LearningProgress(
        id: 'progress1',
        projectId: 'proj1',
        userId: 'user1',
        totalFlashcards: 50,
        masteredFlashcards: 20,
        reviewFlashcards: 15,
        difficultFlashcards: 10,
        unlearnedFlashcards: 5,
        totalQuizAttempts: 30,
        correctAnswers: 24,
        incorrectAnswers: 6,
        createdAt: testDate,
      );

      expect(progress.id, 'progress1');
      expect(progress.projectId, 'proj1');
      expect(progress.userId, 'user1');
      expect(progress.totalFlashcards, 50);
      expect(progress.masteredFlashcards, 20);
    });

    test('should use default values for optional parameters', () {
      final progress = LearningProgress(
        id: 'progress1',
        projectId: 'proj1',
        userId: 'user1',
      );

      expect(progress.totalFlashcards, 0);
      expect(progress.masteredFlashcards, 0);
      expect(progress.reviewFlashcards, 0);
      expect(progress.difficultFlashcards, 0);
      expect(progress.unlearnedFlashcards, 0);
      expect(progress.totalQuizAttempts, 0);
      expect(progress.correctAnswers, 0);
      expect(progress.incorrectAnswers, 0);
    });

    test('should auto-set timestamps when not provided', () {
      final progress = LearningProgress(
        id: 'progress1',
        projectId: 'proj1',
        userId: 'user1',
      );

      expect(progress.lastViewedAt, isNotNull);
      expect(progress.updatedAt, isNotNull);
      expect(progress.createdAt, isNotNull);
    });

    group('Quiz Metrics', () {
      test('quizAccuracy should calculate correct percentage', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalQuizAttempts: 100,
          correctAnswers: 80,
          incorrectAnswers: 20,
        );

        expect(progress.quizAccuracy, 0.8);
      });

      test('quizAccuracy should return 0 when no attempts', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalQuizAttempts: 0,
        );

        expect(progress.quizAccuracy, 0.0);
      });

      test('quizAccuracyPercent should format as percentage', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalQuizAttempts: 100,
          correctAnswers: 85,
        );

        expect(progress.quizAccuracyPercent, '85.0%');
      });

      test('quizAccuracyPercent should handle decimal values', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalQuizAttempts: 33,
          correctAnswers: 22,
        );

        expect(progress.quizAccuracyPercent, '66.7%');
      });
    });

    group('Flashcard Metrics', () {
      test('flashcardProgress should calculate correct percentage', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 100,
          masteredFlashcards: 40,
        );

        expect(progress.flashcardProgress, 0.4);
      });

      test('flashcardProgress should return 0 when no flashcards', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 0,
        );

        expect(progress.flashcardProgress, 0.0);
      });

      test('flashcardProgressPercent should format as percentage', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 50,
          masteredFlashcards: 25,
        );

        expect(progress.flashcardProgressPercent, '50.0%');
      });

      test('learnedFlashcards should sum all learned statuses', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          masteredFlashcards: 20,
          reviewFlashcards: 15,
          difficultFlashcards: 10,
          unlearnedFlashcards: 5,
        );

        expect(progress.learnedFlashcards, 45); // 20 + 15 + 10
      });
    });

    group('Overall Progress', () {
      test('overallProgress should combine flashcard and quiz metrics', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 100,
          masteredFlashcards: 50, // 50% progress
          totalQuizAttempts: 100,
          correctAnswers: 80, // 80% accuracy
        );

        // (0.5 * 0.6) + (0.8 * 0.4) = 0.3 + 0.32 = 0.62
        expect(progress.overallProgress, closeTo(0.62, 0.0001));
      });

      test('overallProgressPercent should format combined progress', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 100,
          masteredFlashcards: 50,
          totalQuizAttempts: 100,
          correctAnswers: 80,
        );

        expect(progress.overallProgressPercent, '62.0%');
      });

      test('overallProgress should handle zeros', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
        );

        expect(progress.overallProgress, 0.0);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 50,
          masteredFlashcards: 20,
        );

        final copied = original.copyWith(
          masteredFlashcards: 30,
          totalQuizAttempts: 10,
        );

        expect(copied.masteredFlashcards, 30);
        expect(copied.totalQuizAttempts, 10);
        expect(copied.id, 'progress1');
        expect(copied.totalFlashcards, 50);
      });

      test('should preserve original values when not specified', () {
        final original = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 100,
          correctAnswers: 50,
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.totalFlashcards, original.totalFlashcards);
        expect(copied.correctAnswers, original.correctAnswers);
      });
    });

    group('JSON Serialization', () {
      test('toJson should convert LearningProgress to Map', () {
        final lastQuizDate = testDate.add(const Duration(hours: 1));
        final lastStudyDate = testDate.add(const Duration(hours: 2));

        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 50,
          masteredFlashcards: 20,
          reviewFlashcards: 15,
          difficultFlashcards: 10,
          unlearnedFlashcards: 5,
          totalQuizAttempts: 30,
          correctAnswers: 24,
          incorrectAnswers: 6,
          lastViewedAt: testDate,
          lastQuizAt: lastQuizDate,
          lastFlashcardStudyAt: lastStudyDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = progress.toJson();

        expect(json['projectId'], 'proj1');
        expect(json['userId'], 'user1');
        expect(json['totalFlashcards'], 50);
        expect(json['masteredFlashcards'], 20);
        expect(json['reviewFlashcards'], 15);
        expect(json['difficultFlashcards'], 10);
        expect(json['unlearnedFlashcards'], 5);
        expect(json['totalQuizAttempts'], 30);
        expect(json['correctAnswers'], 24);
        expect(json['incorrectAnswers'], 6);
        expect(json['lastViewedAt'], isA<Timestamp>());
        expect(json['lastQuizAt'], isA<Timestamp>());
        expect(json['lastFlashcardStudyAt'], isA<Timestamp>());
      });

      test('toJson should handle null optional timestamps', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          lastViewedAt: testDate,
        );

        final json = progress.toJson();

        expect(json['lastQuizAt'], isNull);
        expect(json['lastFlashcardStudyAt'], isNull);
      });

      test('fromJson should create LearningProgress from Map', () {
        final json = {
          'projectId': 'proj1',
          'userId': 'user1',
          'totalFlashcards': 50,
          'masteredFlashcards': 20,
          'reviewFlashcards': 15,
          'difficultFlashcards': 10,
          'unlearnedFlashcards': 5,
          'totalQuizAttempts': 30,
          'correctAnswers': 24,
          'incorrectAnswers': 6,
          'lastViewedAt': Timestamp.fromDate(testDate),
          'lastQuizAt': Timestamp.fromDate(testDate),
          'lastFlashcardStudyAt': Timestamp.fromDate(testDate),
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
        };

        final progress = LearningProgress.fromJson(json, 'progress1');

        expect(progress.id, 'progress1');
        expect(progress.projectId, 'proj1');
        expect(progress.userId, 'user1');
        expect(progress.totalFlashcards, 50);
        expect(progress.masteredFlashcards, 20);
        expect(progress.totalQuizAttempts, 30);
      });

      test('fromJson should use defaults for missing fields', () {
        final json = {'projectId': 'proj1'};

        final progress = LearningProgress.fromJson(json, 'progress1');

        expect(progress.userId, '');
        expect(progress.totalFlashcards, 0);
        expect(progress.masteredFlashcards, 0);
        expect(progress.totalQuizAttempts, 0);
      });

      test('fromJson should handle null timestamps', () {
        final json = {'projectId': 'proj1', 'userId': 'user1'};

        final progress = LearningProgress.fromJson(json, 'progress1');

        expect(progress.lastViewedAt, isNotNull);
        expect(progress.lastQuizAt, isNull);
        expect(progress.lastFlashcardStudyAt, isNull);
        expect(progress.createdAt, isNotNull);
        expect(progress.updatedAt, isNotNull);
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        final progress = LearningProgress(
          id: 'progress1',
          projectId: 'proj1',
          userId: 'user1',
          totalFlashcards: 100,
          masteredFlashcards: 60,
          totalQuizAttempts: 50,
          correctAnswers: 40,
        );

        final str = progress.toString();

        expect(str, contains('proj1'));
        expect(str, contains('60.0%')); // flashcard progress
        expect(str, contains('80.0%')); // quiz accuracy
      });
    });
  });
}
