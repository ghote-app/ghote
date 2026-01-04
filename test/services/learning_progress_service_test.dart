import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/learning_progress.dart';

void main() {
  group('LearningProgress Model Tests', () {
    group('Constructor', () {
      test('should create LearningProgress with required parameters', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
        );

        expect(progress.id, 'progress_1');
        expect(progress.projectId, 'project_1');
        expect(progress.userId, 'user_1');
        expect(progress.totalFlashcards, 0);
        expect(progress.masteredFlashcards, 0);
      });

      test('should create LearningProgress with all parameters', () {
        final now = DateTime.now();
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 50,
          masteredFlashcards: 30,
          reviewFlashcards: 10,
          difficultFlashcards: 5,
          unlearnedFlashcards: 5,
          totalQuizAttempts: 100,
          correctAnswers: 80,
          incorrectAnswers: 20,
          lastViewedAt: now,
          lastFlashcardStudyAt: now,
          lastQuizAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(progress.totalFlashcards, 50);
        expect(progress.masteredFlashcards, 30);
        expect(progress.totalQuizAttempts, 100);
        expect(progress.correctAnswers, 80);
      });
    });

    group('Computed Properties', () {
      test('flashcardProgress should calculate correctly', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 100,
          masteredFlashcards: 75,
        );

        expect(progress.flashcardProgress, 0.75);
      });

      test('flashcardProgress should return 0 when no flashcards', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 0,
        );

        expect(progress.flashcardProgress, 0.0);
      });

      test('quizAccuracy should calculate correctly', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalQuizAttempts: 100,
          correctAnswers: 85,
        );

        expect(progress.quizAccuracy, 0.85);
      });

      test('quizAccuracy should return 0 when no attempts', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalQuizAttempts: 0,
        );

        expect(progress.quizAccuracy, 0.0);
      });

      test('overallProgress should calculate weighted average', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 100,
          masteredFlashcards: 100,
          totalQuizAttempts: 100,
          correctAnswers: 100,
        );

        // overallProgress = (flashcardProgress * 0.6) + (quizAccuracy * 0.4)
        // = (1.0 * 0.6) + (1.0 * 0.4) = 1.0
        expect(progress.overallProgress, 1.0);
      });

      test('learnedFlashcards should sum mastered, review, and difficult', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          masteredFlashcards: 10,
          reviewFlashcards: 5,
          difficultFlashcards: 3,
        );

        expect(progress.learnedFlashcards, 18);
      });

      test('flashcardProgressPercent should format correctly', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 100,
          masteredFlashcards: 75,
        );

        expect(progress.flashcardProgressPercent, '75.0%');
      });

      test('quizAccuracyPercent should format correctly', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalQuizAttempts: 100,
          correctAnswers: 85,
        );

        expect(progress.quizAccuracyPercent, '85.0%');
      });

      test('overallProgressPercent should format correctly', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 100,
          masteredFlashcards: 50,
          totalQuizAttempts: 100,
          correctAnswers: 50,
        );

        // overallProgress = (0.5 * 0.6) + (0.5 * 0.4) = 0.5
        expect(progress.overallProgressPercent, '50.0%');
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 10,
        );

        final copied = original.copyWith(
          totalFlashcards: 50,
          masteredFlashcards: 25,
        );

        expect(copied.totalFlashcards, 50);
        expect(copied.masteredFlashcards, 25);
        expect(copied.id, original.id);
        expect(copied.projectId, original.projectId);
      });

      test('should preserve original values when not specified', () {
        final now = DateTime.now();
        final original = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 100,
          masteredFlashcards: 50,
          lastViewedAt: now,
        );

        final copied = original.copyWith();

        expect(copied.totalFlashcards, original.totalFlashcards);
        expect(copied.masteredFlashcards, original.masteredFlashcards);
        expect(copied.lastViewedAt, original.lastViewedAt);
      });
    });

    group('toJson', () {
      test('should convert LearningProgress to Map', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 50,
          correctAnswers: 40,
        );

        final json = progress.toJson();

        expect(json['projectId'], 'project_1');
        expect(json['userId'], 'user_1');
        expect(json['totalFlashcards'], 50);
        expect(json['correctAnswers'], 40);
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final progress = LearningProgress(
          id: 'progress_1',
          projectId: 'project_1',
          userId: 'user_1',
          totalFlashcards: 100,
          masteredFlashcards: 50,
          totalQuizAttempts: 100,
          correctAnswers: 80,
        );

        final str = progress.toString();
        
        expect(str.contains('project_1'), true);
        expect(str.contains('50.0%'), true);
        expect(str.contains('80.0%'), true);
      });
    });
  });
}
