import '../repositories/project_repository.dart';

/// Use case for deleting a file from a project
/// Follows Single Responsibility Principle - one use case, one action
class DeleteFileUseCase {
  final ProjectRepository _repository;

  DeleteFileUseCase(this._repository);

  /// Execute the use case
  Future<void> call({
    required String projectId,
    required String fileId,
  }) async {
    await _repository.deleteFile(projectId, fileId);
  }
}
