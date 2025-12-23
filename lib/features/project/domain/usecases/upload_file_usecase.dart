import '../../../../models/file_model.dart';
import '../repositories/project_repository.dart';

/// Use case for uploading a file to a project
/// Follows Single Responsibility Principle - one use case, one action
class UploadFileUseCase {
  final ProjectRepository _repository;

  UploadFileUseCase(this._repository);

  /// Execute the use case
  Future<FileModel> call({
    required String projectId,
    required String fileName,
    required String fileType,
    required int sizeBytes,
    required String category,
    required List<int> fileBytes,
    String? localPath,
  }) async {
    return await _repository.uploadFile(
      projectId: projectId,
      fileName: fileName,
      fileType: fileType,
      sizeBytes: sizeBytes,
      category: category,
      fileBytes: fileBytes,
      localPath: localPath,
    );
  }
}
