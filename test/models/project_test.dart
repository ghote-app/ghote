import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/project.dart';

void main() {
  group('Project Model', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final updateDate = DateTime(2024, 1, 20, 14, 0);

    test('should create Project with required parameters', () {
      final project = Project(
        id: 'project_1',
        title: 'Test Project',
        description: 'A test project description',
        ownerId: 'user_1',
        collaboratorIds: [],
        createdAt: testDate,
        lastUpdatedAt: testDate,
        status: 'Active',
        category: 'Study',
      );

      expect(project.id, 'project_1');
      expect(project.title, 'Test Project');
      expect(project.description, 'A test project description');
      expect(project.ownerId, 'user_1');
      expect(project.collaboratorIds, isEmpty);
      expect(project.createdAt, testDate);
      expect(project.lastUpdatedAt, testDate);
      expect(project.status, 'Active');
      expect(project.category, 'Study');
      expect(project.colorTag, isNull);
    });

    test('should create Project with colorTag', () {
      final project = Project(
        id: 'project_1',
        title: 'Colored Project',
        description: null,
        ownerId: 'user_1',
        collaboratorIds: [],
        createdAt: testDate,
        lastUpdatedAt: testDate,
        status: 'Active',
        category: null,
        colorTag: '#FF5733',
      );

      expect(project.colorTag, '#FF5733');
    });

    test('should create Project with collaborators', () {
      final project = Project(
        id: 'project_1',
        title: 'Team Project',
        description: 'Collaborative project',
        ownerId: 'user_1',
        collaboratorIds: ['user_2', 'user_3'],
        createdAt: testDate,
        lastUpdatedAt: testDate,
        status: 'Active',
        category: 'Team',
      );

      expect(project.collaboratorIds, hasLength(2));
      expect(project.collaboratorIds, contains('user_2'));
      expect(project.collaboratorIds, contains('user_3'));
    });

    group('copyWith', () {
      late Project originalProject;

      setUp(() {
        originalProject = Project(
          id: 'project_1',
          title: 'Original Title',
          description: 'Original description',
          ownerId: 'user_1',
          collaboratorIds: ['user_2'],
          createdAt: testDate,
          lastUpdatedAt: testDate,
          status: 'Active',
          category: 'Study',
          colorTag: '#FF0000',
        );
      });

      test('should copy with new title', () {
        final updated = originalProject.copyWith(title: 'New Title');

        expect(updated.title, 'New Title');
        expect(updated.id, originalProject.id);
        expect(updated.description, originalProject.description);
      });

      test('should copy with new status', () {
        final updated = originalProject.copyWith(status: 'Completed');

        expect(updated.status, 'Completed');
        expect(updated.title, originalProject.title);
      });

      test('should copy with new lastUpdatedAt', () {
        final updated = originalProject.copyWith(lastUpdatedAt: updateDate);

        expect(updated.lastUpdatedAt, updateDate);
        expect(updated.createdAt, originalProject.createdAt);
      });

      test('should copy with all parameters', () {
        final updated = originalProject.copyWith(
          id: 'project_2',
          title: 'New Title',
          description: 'New description',
          ownerId: 'user_new',
          collaboratorIds: ['user_3', 'user_4'],
          createdAt: updateDate,
          lastUpdatedAt: updateDate,
          status: 'Archived',
          category: 'Archive',
          colorTag: '#00FF00',
        );

        expect(updated.id, 'project_2');
        expect(updated.title, 'New Title');
        expect(updated.description, 'New description');
        expect(updated.ownerId, 'user_new');
        expect(updated.collaboratorIds, ['user_3', 'user_4']);
        expect(updated.createdAt, updateDate);
        expect(updated.lastUpdatedAt, updateDate);
        expect(updated.status, 'Archived');
        expect(updated.category, 'Archive');
        expect(updated.colorTag, '#00FF00');
      });
    });

    group('JSON serialization', () {
      test('should convert to JSON correctly', () {
        final project = Project(
          id: 'project_1',
          title: 'Test Project',
          description: 'Description',
          ownerId: 'user_1',
          collaboratorIds: ['user_2'],
          createdAt: testDate,
          lastUpdatedAt: updateDate,
          status: 'Active',
          category: 'Study',
          colorTag: '#FF5733',
        );

        final json = project.toJson();

        expect(json['id'], 'project_1');
        expect(json['title'], 'Test Project');
        expect(json['description'], 'Description');
        expect(json['ownerId'], 'user_1');
        expect(json['collaboratorIds'], ['user_2']);
        expect(json['createdAt'], testDate.toIso8601String());
        expect(json['lastUpdatedAt'], updateDate.toIso8601String());
        expect(json['status'], 'Active');
        expect(json['category'], 'Study');
        expect(json['colorTag'], '#FF5733');
      });

      test('should parse from JSON correctly', () {
        final json = {
          'id': 'project_1',
          'title': 'Test Project',
          'description': 'Description',
          'ownerId': 'user_1',
          'collaboratorIds': ['user_2'],
          'createdAt': testDate.toIso8601String(),
          'lastUpdatedAt': updateDate.toIso8601String(),
          'status': 'Active',
          'category': 'Study',
          'colorTag': '#FF5733',
        };

        final project = Project.fromJson(json);

        expect(project.id, 'project_1');
        expect(project.title, 'Test Project');
        expect(project.description, 'Description');
        expect(project.ownerId, 'user_1');
        expect(project.collaboratorIds, ['user_2']);
        expect(project.createdAt, testDate);
        expect(project.lastUpdatedAt, updateDate);
        expect(project.status, 'Active');
        expect(project.category, 'Study');
        expect(project.colorTag, '#FF5733');
      });

      test('should handle null values in JSON', () {
        final json = {
          'id': 'project_1',
          'title': 'Test Project',
          'description': null,
          'ownerId': 'user_1',
          'collaboratorIds': null,
          'createdAt': testDate.toIso8601String(),
          'lastUpdatedAt': updateDate.toIso8601String(),
          'status': 'Active',
          'category': null,
          'colorTag': null,
        };

        final project = Project.fromJson(json);

        expect(project.description, isNull);
        expect(project.collaboratorIds, isEmpty);
        expect(project.category, isNull);
        expect(project.colorTag, isNull);
      });

      test('should round-trip JSON correctly', () {
        final original = Project(
          id: 'project_1',
          title: 'Test Project',
          description: 'Description',
          ownerId: 'user_1',
          collaboratorIds: ['user_2', 'user_3'],
          createdAt: testDate,
          lastUpdatedAt: updateDate,
          status: 'Active',
          category: 'Study',
          colorTag: '#FF5733',
        );

        final json = original.toJson();
        final restored = Project.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.ownerId, original.ownerId);
        expect(restored.collaboratorIds, original.collaboratorIds);
        expect(restored.createdAt, original.createdAt);
        expect(restored.lastUpdatedAt, original.lastUpdatedAt);
        expect(restored.status, original.status);
        expect(restored.category, original.category);
        expect(restored.colorTag, original.colorTag);
      });
    });

    group('Status values', () {
      test('should accept Active status', () {
        final project = Project(
          id: 'p1',
          title: 'Active Project',
          description: null,
          ownerId: 'u1',
          collaboratorIds: [],
          createdAt: testDate,
          lastUpdatedAt: testDate,
          status: 'Active',
          category: null,
        );

        expect(project.status, 'Active');
      });

      test('should accept Completed status', () {
        final project = Project(
          id: 'p1',
          title: 'Completed Project',
          description: null,
          ownerId: 'u1',
          collaboratorIds: [],
          createdAt: testDate,
          lastUpdatedAt: testDate,
          status: 'Completed',
          category: null,
        );

        expect(project.status, 'Completed');
      });

      test('should accept Archived status', () {
        final project = Project(
          id: 'p1',
          title: 'Archived Project',
          description: null,
          ownerId: 'u1',
          collaboratorIds: [],
          createdAt: testDate,
          lastUpdatedAt: testDate,
          status: 'Archived',
          category: null,
        );

        expect(project.status, 'Archived');
      });
    });
  });
}
