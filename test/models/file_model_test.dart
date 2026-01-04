import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/file_model.dart';

void main() {
  group('FileModel', () {
    final testDate = DateTime(2025, 1, 1, 12, 0, 0);

    FileModel createTestFile({
      String id = 'file_1',
      String projectId = 'project_1',
      String name = 'test.pdf',
      String type = 'pdf',
      String category = 'document',
      int sizeBytes = 1024,
      String storageType = 'local',
      String? localPath = '/path/to/file',
      String? cloudPath,
      String? downloadUrl,
      String uploaderId = 'user_1',
      DateTime? uploadedAt,
      Map<String, dynamic>? metadata,
      String? extractedText,
      String? extractionStatus,
    }) {
      return FileModel(
        id: id,
        projectId: projectId,
        name: name,
        type: type,
        category: category,
        sizeBytes: sizeBytes,
        storageType: storageType,
        localPath: localPath,
        cloudPath: cloudPath,
        downloadUrl: downloadUrl,
        uploaderId: uploaderId,
        uploadedAt: uploadedAt ?? testDate,
        metadata: metadata,
        extractedText: extractedText,
        extractionStatus: extractionStatus,
      );
    }

    group('Constructor', () {
      test('should create FileModel with required parameters', () {
        final file = createTestFile();

        expect(file.id, 'file_1');
        expect(file.projectId, 'project_1');
        expect(file.name, 'test.pdf');
        expect(file.type, 'pdf');
        expect(file.category, 'document');
        expect(file.sizeBytes, 1024);
        expect(file.storageType, 'local');
        expect(file.uploaderId, 'user_1');
      });

      test('should create FileModel with optional parameters', () {
        final file = createTestFile(
          extractedText: 'Some extracted text',
          extractionStatus: 'extracted',
        );

        expect(file.extractedText, 'Some extracted text');
        expect(file.extractionStatus, 'extracted');
      });
    });

    group('formattedSize', () {
      test('should format bytes correctly', () {
        final file = createTestFile(sizeBytes: 500);
        expect(file.formattedSize, '500 B');
      });

      test('should format kilobytes correctly', () {
        final file = createTestFile(sizeBytes: 2048);
        expect(file.formattedSize, '2.00 KB');
      });

      test('should format megabytes correctly', () {
        final file = createTestFile(sizeBytes: 5242880);
        expect(file.formattedSize, '5.00 MB');
      });

      test('should format decimal KB correctly', () {
        final file = createTestFile(sizeBytes: 1536);
        expect(file.formattedSize, '1.50 KB');
      });

      test('should format decimal MB correctly', () {
        final file = createTestFile(sizeBytes: 2621440);
        expect(file.formattedSize, '2.50 MB');
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = createTestFile();
        final copied = original.copyWith(
          name: 'new_name.pdf',
          sizeBytes: 2048,
        );

        expect(copied.name, 'new_name.pdf');
        expect(copied.sizeBytes, 2048);
        expect(copied.id, original.id);
        expect(copied.projectId, original.projectId);
      });

      test('should preserve original values when not specified', () {
        final original = createTestFile(
          extractedText: 'original text',
          extractionStatus: 'extracted',
        );
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.extractedText, original.extractedText);
        expect(copied.extractionStatus, original.extractionStatus);
      });
    });

    group('toJson', () {
      test('should convert FileModel to Map', () {
        final file = createTestFile(
          extractedText: 'text content',
          extractionStatus: 'extracted',
        );
        final json = file.toJson();

        expect(json['id'], 'file_1');
        expect(json['projectId'], 'project_1');
        expect(json['name'], 'test.pdf');
        expect(json['type'], 'pdf');
        expect(json['category'], 'document');
        expect(json['sizeBytes'], 1024);
        expect(json['storageType'], 'local');
        expect(json['localPath'], '/path/to/file');
        expect(json['uploaderId'], 'user_1');
        expect(json['extractedText'], 'text content');
        expect(json['extractionStatus'], 'extracted');
      });

      test('should include uploadedAt as ISO8601 string', () {
        final file = createTestFile();
        final json = file.toJson();

        expect(json['uploadedAt'], testDate.toIso8601String());
      });
    });

    group('fromJson', () {
      test('should create FileModel from Map', () {
        final json = {
          'id': 'file_1',
          'projectId': 'project_1',
          'name': 'test.pdf',
          'type': 'pdf',
          'category': 'document',
          'sizeBytes': 1024,
          'storageType': 'local',
          'localPath': '/path/to/file',
          'cloudPath': null,
          'downloadUrl': null,
          'uploaderId': 'user_1',
          'uploadedAt': '2025-01-01T12:00:00.000',
          'metadata': null,
          'extractedText': 'text',
          'extractionStatus': 'extracted',
        };

        final file = FileModel.fromJson(json);

        expect(file.id, 'file_1');
        expect(file.name, 'test.pdf');
        expect(file.extractedText, 'text');
      });

      test('should infer category from type when not provided', () {
        final json = {
          'id': 'file_1',
          'projectId': 'project_1',
          'name': 'image.png',
          'type': 'png',
          'sizeBytes': 1024,
          'storageType': 'local',
          'localPath': null,
          'cloudPath': null,
          'downloadUrl': null,
          'uploaderId': 'user_1',
          'uploadedAt': '2025-01-01T12:00:00.000',
          'metadata': null,
        };

        final file = FileModel.fromJson(json);
        expect(file.category, 'image');
      });

      test('should categorize video types correctly', () {
        final json = {
          'id': 'file_1',
          'projectId': 'project_1',
          'name': 'video.mp4',
          'type': 'mp4',
          'sizeBytes': 1024,
          'storageType': 'cloud',
          'localPath': null,
          'cloudPath': '/cloud/video.mp4',
          'downloadUrl': 'https://example.com/video.mp4',
          'uploaderId': 'user_1',
          'uploadedAt': '2025-01-01T12:00:00.000',
          'metadata': null,
        };

        final file = FileModel.fromJson(json);
        expect(file.category, 'video');
      });

      test('should categorize audio types correctly', () {
        final json = {
          'id': 'file_1',
          'projectId': 'project_1',
          'name': 'audio.mp3',
          'type': 'mp3',
          'sizeBytes': 1024,
          'storageType': 'local',
          'localPath': '/path/audio.mp3',
          'cloudPath': null,
          'downloadUrl': null,
          'uploaderId': 'user_1',
          'uploadedAt': '2025-01-01T12:00:00.000',
          'metadata': null,
        };

        final file = FileModel.fromJson(json);
        expect(file.category, 'audio');
      });

      test('should categorize unknown types as other', () {
        final json = {
          'id': 'file_1',
          'projectId': 'project_1',
          'name': 'file.xyz',
          'type': 'xyz',
          'sizeBytes': 1024,
          'storageType': 'local',
          'localPath': null,
          'cloudPath': null,
          'downloadUrl': null,
          'uploaderId': 'user_1',
          'uploadedAt': '2025-01-01T12:00:00.000',
          'metadata': null,
        };

        final file = FileModel.fromJson(json);
        expect(file.category, 'other');
      });
    });

    group('JSON round trip', () {
      test('should preserve all data through JSON serialization', () {
        final original = createTestFile(
          cloudPath: '/cloud/path',
          downloadUrl: 'https://example.com/file.pdf',
          metadata: {'key': 'value'},
          extractedText: 'Extracted content',
          extractionStatus: 'extracted',
        );

        final json = original.toJson();
        final restored = FileModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.projectId, original.projectId);
        expect(restored.name, original.name);
        expect(restored.type, original.type);
        expect(restored.category, original.category);
        expect(restored.sizeBytes, original.sizeBytes);
        expect(restored.storageType, original.storageType);
        expect(restored.localPath, original.localPath);
        expect(restored.cloudPath, original.cloudPath);
        expect(restored.downloadUrl, original.downloadUrl);
        expect(restored.uploaderId, original.uploaderId);
        expect(restored.extractedText, original.extractedText);
        expect(restored.extractionStatus, original.extractionStatus);
      });
    });
  });
}
