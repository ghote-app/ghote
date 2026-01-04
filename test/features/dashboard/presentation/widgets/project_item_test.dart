import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/features/dashboard/presentation/widgets/project_item.dart';

void main() {
  group('ProjectItem', () {
    test('should create ProjectItem with required parameters', () {
      const item = ProjectItem(
        id: 'project_1',
        title: 'Test Project',
        status: 'Active',
        documentCount: 5,
        lastUpdated: '2025-01-01',
        image: 'assets/test.png',
        progress: 0.5,
        category: 'Study',
      );

      expect(item.id, 'project_1');
      expect(item.title, 'Test Project');
      expect(item.status, 'Active');
      expect(item.documentCount, 5);
      expect(item.lastUpdated, '2025-01-01');
      expect(item.image, 'assets/test.png');
      expect(item.progress, 0.5);
      expect(item.category, 'Study');
      expect(item.colorTag, null);
      expect(item.description, null);
    });

    test('should create ProjectItem with optional parameters', () {
      const item = ProjectItem(
        id: 'project_1',
        title: 'Test Project',
        status: 'Active',
        documentCount: 5,
        lastUpdated: '2025-01-01',
        image: 'assets/test.png',
        progress: 0.5,
        category: 'Study',
        colorTag: '#FF5733',
        description: 'This is a test project',
      );

      expect(item.colorTag, '#FF5733');
      expect(item.description, 'This is a test project');
    });

    test('should handle different status values', () {
      const activeItem = ProjectItem(
        id: 'project_1',
        title: 'Test',
        status: 'Active',
        documentCount: 0,
        lastUpdated: '',
        image: '',
        progress: 0.0,
        category: '',
      );
      expect(activeItem.status, 'Active');

      const completedItem = ProjectItem(
        id: 'project_2',
        title: 'Test',
        status: 'Completed',
        documentCount: 0,
        lastUpdated: '',
        image: '',
        progress: 1.0,
        category: '',
      );
      expect(completedItem.status, 'Completed');

      const archivedItem = ProjectItem(
        id: 'project_3',
        title: 'Test',
        status: 'Archived',
        documentCount: 0,
        lastUpdated: '',
        image: '',
        progress: 0.0,
        category: '',
      );
      expect(archivedItem.status, 'Archived');
    });

    test('should handle progress values from 0 to 1', () {
      const zeroProgress = ProjectItem(
        id: 'project_1',
        title: 'Test',
        status: 'Active',
        documentCount: 0,
        lastUpdated: '',
        image: '',
        progress: 0.0,
        category: '',
      );
      expect(zeroProgress.progress, 0.0);

      const halfProgress = ProjectItem(
        id: 'project_2',
        title: 'Test',
        status: 'Active',
        documentCount: 0,
        lastUpdated: '',
        image: '',
        progress: 0.5,
        category: '',
      );
      expect(halfProgress.progress, 0.5);

      const fullProgress = ProjectItem(
        id: 'project_3',
        title: 'Test',
        status: 'Completed',
        documentCount: 0,
        lastUpdated: '',
        image: '',
        progress: 1.0,
        category: '',
      );
      expect(fullProgress.progress, 1.0);
    });

    test('should handle high document counts', () {
      const item = ProjectItem(
        id: 'project_1',
        title: 'Test',
        status: 'Active',
        documentCount: 1000,
        lastUpdated: '',
        image: '',
        progress: 0.0,
        category: '',
      );
      expect(item.documentCount, 1000);
    });
  });
}
