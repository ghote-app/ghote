import '../../../../models/file_model.dart';

/// Repository interface for project operations
/// Following Clean Architecture - domain layer only contains interfaces
/// Implementation is in data layer (project_repository_impl.dart)
abstract class ProjectRepository {
  /// Watch all files for a project
  Stream<List<FileModel>> watchFiles(String projectId);
  
  /// Get a single file by ID
  Future<FileModel?> getFile(String projectId, String fileId);
  
  /// Upload a file to the project
  Future<FileModel> uploadFile({
    required String projectId,
    required String fileName,
    required String fileType,
    required int sizeBytes,
    required String category,
    required List<int> fileBytes,
    String? localPath,
  });
  
  /// Delete a file from the project
  Future<void> deleteFile(String projectId, String fileId);
  
  /// Update project info
  Future<void> updateProjectInfo({
    required String projectId,
    required String name,
    String? description,
    String? color,
  });
  
  /// Get project title
  Future<String?> getProjectTitle(String projectId);
}
