import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/question.dart';

void main() {
  group('Question Model', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('MCQ Single Choice', () {
      test('should create MCQ single choice question', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'What is 2+2?',
          questionType: 'mcq-single',
          options: ['1', '2', '3', '4'],
          correctAnswer: '4',
          explanation: '2+2 equals 4',
          createdAt: testDate,
          difficulty: 'easy',
        );

        expect(question.id, 'q1');
        expect(question.questionText, 'What is 2+2?');
        expect(question.questionType, 'mcq-single');
        expect(question.options, ['1', '2', '3', '4']);
        expect(question.correctAnswer, '4');
        expect(question.difficulty, 'easy');
      });

      test('should identify as MCQ single', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-single',
          createdAt: testDate,
        );

        expect(question.isMcq, true);
        expect(question.isMcqSingle, true);
        expect(question.isMcqMultiple, false);
        expect(question.isOpenEnded, false);
      });

      test('should identify legacy mcq type as single choice', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq',
          createdAt: testDate,
        );

        expect(question.isMcq, true);
        expect(question.isMcqSingle, true);
      });
    });

    group('MCQ Multiple Choice', () {
      test('should create MCQ multiple choice question', () {
        final question = Question(
          id: 'q2',
          projectId: 'proj1',
          questionText: 'Select all prime numbers',
          questionType: 'mcq-multiple',
          options: ['1', '2', '3', '4'],
          correctAnswers: ['2', '3'],
          explanation: '2 and 3 are prime numbers',
          createdAt: testDate,
          difficulty: 'medium',
        );

        expect(question.questionType, 'mcq-multiple');
        expect(question.correctAnswers, ['2', '3']);
        expect(question.correctAnswer, isNull);
      });

      test('should identify as MCQ multiple', () {
        final question = Question(
          id: 'q2',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-multiple',
          createdAt: testDate,
        );

        expect(question.isMcq, true);
        expect(question.isMcqSingle, false);
        expect(question.isMcqMultiple, true);
        expect(question.isOpenEnded, false);
      });
    });

    group('Open-ended Questions', () {
      test('should create open-ended question', () {
        final question = Question(
          id: 'q3',
          projectId: 'proj1',
          questionText: 'Explain quantum physics',
          questionType: 'open-ended',
          keywords: ['quantum', 'physics', 'wave function'],
          explanation: 'Key concepts include wave-particle duality',
          createdAt: testDate,
          difficulty: 'hard',
        );

        expect(question.questionType, 'open-ended');
        expect(question.keywords, ['quantum', 'physics', 'wave function']);
        expect(question.options, isNull);
        expect(question.correctAnswer, isNull);
      });

      test('should identify as open-ended', () {
        final question = Question(
          id: 'q3',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'open-ended',
          createdAt: testDate,
        );

        expect(question.isMcq, false);
        expect(question.isMcqSingle, false);
        expect(question.isMcqMultiple, false);
        expect(question.isOpenEnded, true);
      });
    });

    group('Default Values', () {
      test('should use default difficulty as medium', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-single',
          createdAt: testDate,
        );

        expect(question.difficulty, 'medium');
      });

      test('should allow null optional fields', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'open-ended',
          createdAt: testDate,
        );

        expect(question.fileId, isNull);
        expect(question.options, isNull);
        expect(question.correctAnswer, isNull);
        expect(question.correctAnswers, isNull);
        expect(question.explanation, isNull);
        expect(question.keywords, isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Original question?',
          questionType: 'mcq-single',
          difficulty: 'easy',
          createdAt: testDate,
        );

        final copied = original.copyWith(
          questionText: 'Updated question?',
          difficulty: 'hard',
        );

        expect(copied.questionText, 'Updated question?');
        expect(copied.difficulty, 'hard');
        expect(copied.id, 'q1');
        expect(copied.projectId, 'proj1');
      });

      test('should preserve original values when not specified', () {
        final original = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-multiple',
          correctAnswers: ['A', 'B'],
          difficulty: 'hard',
          createdAt: testDate,
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.questionText, original.questionText);
        expect(copied.correctAnswers, original.correctAnswers);
        expect(copied.difficulty, original.difficulty);
      });
    });

    group('JSON Serialization', () {
      test('toJson should convert Question to Map', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          fileId: 'file1',
          questionText: 'What is Flutter?',
          questionType: 'mcq-single',
          options: ['A framework', 'A language', 'A tool'],
          correctAnswer: 'A framework',
          explanation: 'Flutter is a UI framework',
          createdAt: testDate,
          difficulty: 'easy',
          keywords: ['flutter', 'framework'],
        );

        final json = question.toJson();

        expect(json['id'], 'q1');
        expect(json['projectId'], 'proj1');
        expect(json['fileId'], 'file1');
        expect(json['questionText'], 'What is Flutter?');
        expect(json['questionType'], 'mcq-single');
        expect(json['options'], ['A framework', 'A language', 'A tool']);
        expect(json['correctAnswer'], 'A framework');
        expect(json['explanation'], 'Flutter is a UI framework');
        expect(json['createdAt'], testDate.toIso8601String());
        expect(json['difficulty'], 'easy');
        expect(json['keywords'], ['flutter', 'framework']);
      });

      test('fromJson should create Question from Map', () {
        final json = {
          'id': 'q1',
          'projectId': 'proj1',
          'fileId': 'file1',
          'questionText': 'What is Dart?',
          'questionType': 'mcq-single',
          'options': ['Language', 'Framework'],
          'correctAnswer': 'Language',
          'explanation': 'Dart is a programming language',
          'createdAt': testDate.toIso8601String(),
          'difficulty': 'medium',
          'keywords': ['dart', 'language'],
        };

        final question = Question.fromJson(json);

        expect(question.id, 'q1');
        expect(question.projectId, 'proj1');
        expect(question.fileId, 'file1');
        expect(question.questionText, 'What is Dart?');
        expect(question.questionType, 'mcq-single');
        expect(question.options, ['Language', 'Framework']);
        expect(question.correctAnswer, 'Language');
        expect(question.explanation, 'Dart is a programming language');
        expect(question.createdAt, testDate);
        expect(question.difficulty, 'medium');
        expect(question.keywords, ['dart', 'language']);
      });

      test('fromJson should handle null optional fields', () {
        final json = {
          'id': 'q1',
          'projectId': 'proj1',
          'questionText': 'Test?',
          'questionType': 'open-ended',
          'createdAt': testDate.toIso8601String(),
        };

        final question = Question.fromJson(json);

        expect(question.fileId, isNull);
        expect(question.options, isNull);
        expect(question.correctAnswer, isNull);
        expect(question.correctAnswers, isNull);
        expect(question.explanation, isNull);
        expect(question.keywords, isNull);
        expect(question.difficulty, 'medium'); // default
      });

      test('JSON round trip should preserve all data', () {
        final original = Question(
          id: 'q1',
          projectId: 'proj1',
          fileId: 'file1',
          questionText: 'Test question?',
          questionType: 'mcq-multiple',
          options: ['A', 'B', 'C'],
          correctAnswers: ['A', 'C'],
          explanation: 'Explanation here',
          createdAt: testDate,
          difficulty: 'hard',
          keywords: ['test', 'example'],
        );

        final json = original.toJson();
        final restored = Question.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.projectId, original.projectId);
        expect(restored.fileId, original.fileId);
        expect(restored.questionText, original.questionText);
        expect(restored.questionType, original.questionType);
        expect(restored.options, original.options);
        expect(restored.correctAnswers, original.correctAnswers);
        expect(restored.explanation, original.explanation);
        expect(restored.createdAt, original.createdAt);
        expect(restored.difficulty, original.difficulty);
        expect(restored.keywords, original.keywords);
      });
    });

    group('difficultyLabel', () {
      test('should return 簡單 for easy', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-single',
          difficulty: 'easy',
          createdAt: testDate,
        );
        expect(question.difficultyLabel, '簡單');
      });

      test('should return 中等 for medium', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-single',
          difficulty: 'medium',
          createdAt: testDate,
        );
        expect(question.difficultyLabel, '中等');
      });

      test('should return 困難 for hard', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-single',
          difficulty: 'hard',
          createdAt: testDate,
        );
        expect(question.difficultyLabel, '困難');
      });

      test('should return 中等 for unknown difficulty', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Test?',
          questionType: 'mcq-single',
          difficulty: 'unknown',
          createdAt: testDate,
        );
        expect(question.difficultyLabel, '中等');
      });
    });

    group('Edge Cases', () {
      test('should handle very long question text', () {
        final longText = 'A' * 5000;
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: longText,
          questionType: 'mcq-single',
          createdAt: testDate,
        );
        expect(question.questionText.length, 5000);
      });

      test('should handle special characters in question', () {
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: '特殊字符 <>&"\' \n\t émojis 🎉',
          questionType: 'mcq-single',
          createdAt: testDate,
        );
        expect(question.questionText, contains('🎉'));
      });

      test('should handle copyWith with all fields', () {
        final original = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Original',
          questionType: 'open-ended',
          createdAt: testDate,
        );

        final updated = original.copyWith(
          fileId: 'file123',
          options: ['A', 'B', 'C'],
          explanation: 'New explanation',
          keywords: ['new', 'keywords'],
        );

        expect(updated.fileId, 'file123');
        expect(updated.options, ['A', 'B', 'C']);
        expect(updated.explanation, 'New explanation');
        expect(updated.keywords, ['new', 'keywords']);
        expect(updated.id, 'q1'); // preserved
      });

      test('should handle MCQ with many options', () {
        final manyOptions = List.generate(20, (i) => 'Option $i');
        final question = Question(
          id: 'q1',
          projectId: 'proj1',
          questionText: 'Choose all that apply',
          questionType: 'mcq-multiple',
          options: manyOptions,
          correctAnswers: ['Option 0', 'Option 5', 'Option 10'],
          createdAt: testDate,
        );

        expect(question.options?.length, 20);
        expect(question.correctAnswers?.length, 3);
      });
    });
  });
}
