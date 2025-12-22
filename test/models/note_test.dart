import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/note.dart';

void main() {
  group('Note Model', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    test('should create Note with required parameters', () {
      final note = Note(
        id: 'note_1',
        projectId: 'project_1',
        title: 'Test Note',
        mainConcepts: ['Concept 1', 'Concept 2'],
        detailedExplanation: 'This is a test explanation',
        keywords: ['keyword1', 'keyword2'],
        createdAt: testDate,
      );

      expect(note.id, 'note_1');
      expect(note.projectId, 'project_1');
      expect(note.title, 'Test Note');
      expect(note.mainConcepts, ['Concept 1', 'Concept 2']);
      expect(note.importance, 'medium'); // default value
      expect(note.isFavorite, false); // default value
    });

    test('should use default values for optional parameters', () {
      final note = Note(
        id: 'note_1',
        projectId: 'project_1',
        title: 'Test Note',
        mainConcepts: [],
        detailedExplanation: 'Explanation',
        keywords: [],
        createdAt: testDate,
      );

      expect(note.importance, 'medium');
      expect(note.isFavorite, false);
      expect(note.fileId, isNull);
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Original Title',
          mainConcepts: ['Concept 1'],
          detailedExplanation: 'Original explanation',
          keywords: ['keyword1'],
          createdAt: testDate,
        );

        final copied = original.copyWith(
          title: 'Updated Title',
          importance: 'high',
          isFavorite: true,
        );

        expect(copied.title, 'Updated Title');
        expect(copied.importance, 'high');
        expect(copied.isFavorite, true);
        // Original values should be preserved
        expect(copied.id, 'note_1');
        expect(copied.projectId, 'project_1');
      });

      test('should preserve original values when not specified', () {
        final original = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Original Title',
          mainConcepts: ['Concept 1'],
          detailedExplanation: 'Original explanation',
          importance: 'high',
          keywords: ['keyword1'],
          createdAt: testDate,
          isFavorite: true,
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.title, original.title);
        expect(copied.importance, original.importance);
        expect(copied.isFavorite, original.isFavorite);
      });
    });

    group('JSON serialization', () {
      test('toJson should convert Note to Map', () {
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          fileId: 'file_1',
          title: 'Test Note',
          mainConcepts: ['Concept 1', 'Concept 2'],
          detailedExplanation: 'Detailed explanation',
          importance: 'high',
          keywords: ['keyword1', 'keyword2'],
          createdAt: testDate,
          isFavorite: true,
        );

        final json = note.toJson();

        expect(json['id'], 'note_1');
        expect(json['projectId'], 'project_1');
        expect(json['fileId'], 'file_1');
        expect(json['title'], 'Test Note');
        expect(json['mainConcepts'], ['Concept 1', 'Concept 2']);
        expect(json['detailedExplanation'], 'Detailed explanation');
        expect(json['importance'], 'high');
        expect(json['keywords'], ['keyword1', 'keyword2']);
        expect(json['createdAt'], testDate.toIso8601String());
        expect(json['isFavorite'], true);
      });

      test('fromJson should create Note from Map', () {
        final json = {
          'id': 'note_1',
          'projectId': 'project_1',
          'fileId': 'file_1',
          'title': 'Test Note',
          'mainConcepts': ['Concept 1', 'Concept 2'],
          'detailedExplanation': 'Detailed explanation',
          'importance': 'high',
          'keywords': ['keyword1', 'keyword2'],
          'createdAt': testDate.toIso8601String(),
          'isFavorite': true,
        };

        final note = Note.fromJson(json);

        expect(note.id, 'note_1');
        expect(note.projectId, 'project_1');
        expect(note.fileId, 'file_1');
        expect(note.title, 'Test Note');
        expect(note.mainConcepts, ['Concept 1', 'Concept 2']);
        expect(note.detailedExplanation, 'Detailed explanation');
        expect(note.importance, 'high');
        expect(note.keywords, ['keyword1', 'keyword2']);
        expect(note.createdAt, testDate);
        expect(note.isFavorite, true);
      });

      test('fromJson should use default values for optional fields', () {
        final json = {
          'id': 'note_1',
          'projectId': 'project_1',
          'title': 'Test Note',
          'mainConcepts': [],
          'detailedExplanation': 'Explanation',
          'keywords': [],
          'createdAt': testDate.toIso8601String(),
        };

        final note = Note.fromJson(json);

        expect(note.fileId, isNull);
        expect(note.importance, 'medium');
        expect(note.isFavorite, false);
      });

      test('JSON round trip should preserve all data', () {
        final original = Note(
          id: 'note_1',
          projectId: 'project_1',
          fileId: 'file_1',
          title: 'Test Note',
          mainConcepts: ['Concept 1', 'Concept 2'],
          detailedExplanation: 'Detailed explanation',
          importance: 'high',
          keywords: ['keyword1', 'keyword2'],
          createdAt: testDate,
          isFavorite: true,
        );

        final json = original.toJson();
        final restored = Note.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.projectId, original.projectId);
        expect(restored.fileId, original.fileId);
        expect(restored.title, original.title);
        expect(restored.mainConcepts, original.mainConcepts);
        expect(restored.detailedExplanation, original.detailedExplanation);
        expect(restored.importance, original.importance);
        expect(restored.keywords, original.keywords);
        expect(restored.createdAt, original.createdAt);
        expect(restored.isFavorite, original.isFavorite);
      });
    });

    group('importanceLabel', () {
      test('should return correct label for high importance', () {
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Test',
          mainConcepts: [],
          detailedExplanation: '',
          importance: 'high',
          keywords: [],
          createdAt: testDate,
        );
        expect(note.importanceLabel, '高');
      });

      test('should return correct label for medium importance', () {
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Test',
          mainConcepts: [],
          detailedExplanation: '',
          importance: 'medium',
          keywords: [],
          createdAt: testDate,
        );
        expect(note.importanceLabel, '中');
      });

      test('should return correct label for low importance', () {
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Test',
          mainConcepts: [],
          detailedExplanation: '',
          importance: 'low',
          keywords: [],
          createdAt: testDate,
        );
        expect(note.importanceLabel, '低');
      });

      test('should return default label for unknown importance', () {
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Test',
          mainConcepts: [],
          detailedExplanation: '',
          importance: 'unknown',
          keywords: [],
          createdAt: testDate,
        );
        expect(note.importanceLabel, '中');
      });
    });

    group('Edge Cases', () {
      test('should handle very long title', () {
        final longTitle = 'A' * 1000;
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: longTitle,
          mainConcepts: [],
          detailedExplanation: 'Explanation',
          keywords: [],
          createdAt: testDate,
        );
        expect(note.title.length, 1000);
      });

      test('should handle special characters in content', () {
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Special \n\t<>&"',
          mainConcepts: ['概念 with émojis 🎉'],
          detailedExplanation: 'Explanation with 中文',
          keywords: ['key<>word'],
          createdAt: testDate,
        );
        expect(note.title, contains('\n'));
        expect(note.mainConcepts.first, contains('🎉'));
      });

      test('should handle copyWith with fileId changes', () {
        final note = Note(
          id: 'note_1',
          projectId: 'project_1',
          title: 'Test',
          mainConcepts: [],
          detailedExplanation: 'Test',
          keywords: [],
          createdAt: testDate,
        );

        final withFile = note.copyWith(fileId: 'file123');
        expect(withFile.fileId, 'file123');

        // copyWith preserves original when not changed
        final again = withFile.copyWith(title: 'New Title');
        expect(again.fileId, 'file123');
      });
    });
  });
}
