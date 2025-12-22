import '../../../../models/file_model.dart';
import '../repositories/project_repository.dart';

/// Use case for watching files in a project
/// Follows Single Responsibility Principle - one use case, one action
class WatchFilesUseCase {
  final ProjectRepository _repository;

  WatchFilesUseCase(this._repository);

  /// Execute the use case - returns a stream of files
  Stream<List<FileModel>> call(String projectId) {
    return _repository.watchFiles(projectId);
  }
}
