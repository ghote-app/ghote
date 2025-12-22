import '../../features/project/domain/repositories/project_repository.dart';
import '../../features/project/domain/usecases/delete_file_usecase.dart';
import '../../features/project/domain/usecases/watch_files_usecase.dart';
import '../../features/project/domain/usecases/upload_file_usecase.dart';
import '../../features/project/data/repositories/project_repository_impl.dart';

/// Simple dependency injection container
/// Provides singleton instances of repositories and use cases
/// Following Dependency Inversion Principle
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Lazy-initialized singletons
  ProjectRepository? _projectRepository;
  DeleteFileUseCase? _deleteFileUseCase;
  WatchFilesUseCase? _watchFilesUseCase;
  UploadFileUseCase? _uploadFileUseCase;

  /// Get ProjectRepository instance
  ProjectRepository get projectRepository {
    _projectRepository ??= ProjectRepositoryImpl();
    return _projectRepository!;
  }

  /// Get DeleteFileUseCase instance
  DeleteFileUseCase get deleteFileUseCase {
    _deleteFileUseCase ??= DeleteFileUseCase(projectRepository);
    return _deleteFileUseCase!;
  }

  /// Get WatchFilesUseCase instance
  WatchFilesUseCase get watchFilesUseCase {
    _watchFilesUseCase ??= WatchFilesUseCase(projectRepository);
    return _watchFilesUseCase!;
  }

  /// Get UploadFileUseCase instance
  UploadFileUseCase get uploadFileUseCase {
    _uploadFileUseCase ??= UploadFileUseCase(projectRepository);
    return _uploadFileUseCase!;
  }

  /// Reset all instances (useful for testing)
  void reset() {
    _projectRepository = null;
    _deleteFileUseCase = null;
    _watchFilesUseCase = null;
    _uploadFileUseCase = null;
  }
}

/// Global service locator instance
final sl = ServiceLocator();
