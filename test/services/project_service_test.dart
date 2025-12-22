import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/project.dart';
import 'package:ghote/models/file_model.dart';
import 'package:ghote/services/project_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ProjectService projectService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    projectService = ProjectService(firestore: fakeFirestore);
  });

  group('ProjectService', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    Project createTestProject({
      String id = 'project_1',
      String title = 'Test Project',
      String ownerId = 'user_1',
    }) {
      return Project(
        id: id,
        title: title,
        description: 'Test description',
        ownerId: ownerId,
        collaboratorIds: [],
        createdAt: testDate,
        lastUpdatedAt: testDate,
        status: 'Active',
        category: 'Study',
      );
    }

    FileModel createTestFile({String id = 'file_1', String projectId = 'project_1'}) {
      return FileModel(
        id: id,
        projectId: projectId,
        name: 'test_file.pdf',
        type: 'pdf',
        category: 'document',
        sizeBytes: 1024,
        storageType: 'cloud',
        localPath: null,
        cloudPath: 'files/test_file.pdf',
        downloadUrl: 'https://example.com/file.pdf',
        uploaderId: 'user_1',
        uploadedAt: testDate,
        metadata: null,
      );
    }

    group('createProject', () {
      test('should create project in Firestore', () async {
        final project = createTestProject();

        await projectService.createProject(project);

        final doc =
            await fakeFirestore.collection('projects').doc('project_1').get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['title'], 'Test Project');
        expect(doc.data()?['ownerId'], 'user_1');
      });

      test('should store all project fields', () async {
        final project = createTestProject();

        await projectService.createProject(project);

        final doc =
            await fakeFirestore.collection('projects').doc('project_1').get();
        expect(doc.data()?['description'], 'Test description');
        expect(doc.data()?['status'], 'Active');
        expect(doc.data()?['category'], 'Study');
      });
    });

    group('getProject', () {
      test('should retrieve existing project', () async {
        final project = createTestProject();
        await projectService.createProject(project);

        final retrieved = await projectService.getProject('project_1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'project_1');
        expect(retrieved.title, 'Test Project');
        expect(retrieved.ownerId, 'user_1');
      });

      test('should return null for non-existent project', () async {
        final retrieved = await projectService.getProject('non_existent');

        expect(retrieved, isNull);
      });
    });

    group('updateProject', () {
      test('should update project fields', () async {
        final project = createTestProject();
        await projectService.createProject(project);

        final updated = project.copyWith(
          title: 'Updated Title',
          status: 'Completed',
        );
        await projectService.updateProject(updated);

        final retrieved = await projectService.getProject('project_1');
        expect(retrieved?.title, 'Updated Title');
        expect(retrieved?.status, 'Completed');
      });
    });

    group('deleteProject', () {
      test('should remove project document', () async {
        final project = createTestProject();
        await projectService.createProject(project);

        await projectService.deleteProject('project_1');

        final retrieved = await projectService.getProject('project_1');
        expect(retrieved, isNull);
      });
    });

    group('deleteProjectDeep', () {
      test('should remove project and all files', () async {
        final project = createTestProject();
        await projectService.createProject(project);

        // Add files to project
        await projectService.addFileMetadata('project_1', createTestFile(id: 'file_1'));
        await projectService.addFileMetadata('project_1', createTestFile(id: 'file_2'));

        // Verify files exist
        final filesBeforeDelete = await fakeFirestore
            .collection('projects')
            .doc('project_1')
            .collection('files')
            .get();
        expect(filesBeforeDelete.docs.length, 2);

        // Delete project deep
        await projectService.deleteProjectDeep('project_1');

        // Verify project is gone
        final retrieved = await projectService.getProject('project_1');
        expect(retrieved, isNull);

        // Verify files are gone
        final filesAfterDelete = await fakeFirestore
            .collection('projects')
            .doc('project_1')
            .collection('files')
            .get();
        expect(filesAfterDelete.docs.length, 0);
      });
    });

    group('watchProjectsByOwner', () {
      test('should stream projects filtered by owner', () async {
        // Create projects for different owners
        await projectService.createProject(
          createTestProject(id: 'p1', title: 'User1 Project', ownerId: 'user_1'),
        );
        await projectService.createProject(
          createTestProject(id: 'p2', title: 'User2 Project', ownerId: 'user_2'),
        );
        await projectService.createProject(
          createTestProject(id: 'p3', title: 'Another User1 Project', ownerId: 'user_1'),
        );

        final stream = projectService.watchProjectsByOwner('user_1');
        final projects = await stream.first;

        expect(projects.length, 2);
        expect(projects.every((p) => p.ownerId == 'user_1'), isTrue);
      });

      test('should return empty list for owner with no projects', () async {
        final stream = projectService.watchProjectsByOwner('non_existent');
        final projects = await stream.first;

        expect(projects, isEmpty);
      });
    });

    group('File metadata operations', () {
      setUp(() async {
        final project = createTestProject();
        await projectService.createProject(project);
      });

      test('addFileMetadata should add file to project', () async {
        final file = createTestFile();

        await projectService.addFileMetadata('project_1', file);

        final doc = await fakeFirestore
            .collection('projects')
            .doc('project_1')
            .collection('files')
            .doc('file_1')
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['name'], 'test_file.pdf');
      });

      test('updateFileMetadata should update file fields', () async {
        final file = createTestFile();
        await projectService.addFileMetadata('project_1', file);

        final updatedFile = FileModel(
          id: 'file_1',
          projectId: 'project_1',
          name: 'updated_file.pdf',
          type: 'pdf',
          category: 'document',
          sizeBytes: 2048,
          storageType: 'cloud',
          localPath: null,
          cloudPath: 'files/updated_file.pdf',
          downloadUrl: 'https://example.com/updated.pdf',
          uploaderId: 'user_1',
          uploadedAt: testDate,
          metadata: null,
        );
        await projectService.updateFileMetadata('project_1', updatedFile);

        final doc = await fakeFirestore
            .collection('projects')
            .doc('project_1')
            .collection('files')
            .doc('file_1')
            .get();
        expect(doc.data()?['name'], 'updated_file.pdf');
      });

      test('deleteFileMetadata should remove file', () async {
        final file = createTestFile();
        await projectService.addFileMetadata('project_1', file);

        await projectService.deleteFileMetadata('project_1', 'file_1');

        final doc = await fakeFirestore
            .collection('projects')
            .doc('project_1')
            .collection('files')
            .doc('file_1')
            .get();
        expect(doc.exists, isFalse);
      });

      test('getProjectFileCount should return correct count', () async {
        await projectService.addFileMetadata('project_1', createTestFile(id: 'f1'));
        await projectService.addFileMetadata('project_1', createTestFile(id: 'f2'));
        await projectService.addFileMetadata('project_1', createTestFile(id: 'f3'));

        final count = await projectService.getProjectFileCount('project_1');

        expect(count, 3);
      });

      test('getProjectFileCount should return 0 for empty project', () async {
        final count = await projectService.getProjectFileCount('project_1');

        expect(count, 0);
      });
    });

    group('watchFiles', () {
      test('should stream files for project', () async {
        await projectService.createProject(createTestProject());
        await projectService.addFileMetadata('project_1', createTestFile(id: 'f1'));
        await projectService.addFileMetadata('project_1', createTestFile(id: 'f2'));

        final stream = projectService.watchFiles('project_1');
        final files = await stream.first;

        expect(files.length, 2);
      });
    });
  });
}
