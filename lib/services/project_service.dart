import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project.dart';
import '../models/file_model.dart';

/// ProjectService centralizes CRUD for projects and their file metadata
/// stored in Firestore using the following structure:
///   /projects/{projectId}
///     /files/{fileId}
class ProjectService {
  ProjectService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _projectsCol =>
      _firestore.collection('projects');

  DocumentReference<Map<String, dynamic>> _projectDoc(String projectId) =>
      _projectsCol.doc(projectId);

  CollectionReference<Map<String, dynamic>> _filesCol(String projectId) =>
      _projectDoc(projectId).collection('files');

  // ----------------------
  // Project CRUD
  // ----------------------
  Future<void> createProject(Project project) async {
    await _projectDoc(project.id).set(project.toJson());
  }

  Future<Project?> getProject(String projectId) async {
    final snap = await _projectDoc(projectId).get();
    if (!snap.exists) return null;
    return Project.fromJson(snap.data()!);
  }

  Future<void> updateProject(Project project) async {
    await _projectDoc(project.id).update(project.toJson());
  }

  Future<void> deleteProject(String projectId) async {
    await _projectDoc(projectId).delete();
  }

  /// Delete project and all file metadata under /projects/{projectId}/files
  Future<void> deleteProjectDeep(String projectId) async {
    // Delete files subcollection in batches
    final filesSnap = await _filesCol(projectId).get();
    final batch = _firestore.batch();
    for (final doc in filesSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await _projectDoc(projectId).delete();
  }

  Stream<List<Project>> watchProjectsByOwner(String ownerId) {
    return _projectsCol
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => Project.fromJson(doc.data()))
            .toList());
  }

  // ----------------------
  // File metadata CRUD
  // ----------------------
  Future<void> addFileMetadata(String projectId, FileModel file) async {
    await _filesCol(projectId).doc(file.id).set(file.toJson());
  }

  Future<void> updateFileMetadata(String projectId, FileModel file) async {
    await _filesCol(projectId).doc(file.id).update(file.toJson());
  }

  Future<void> deleteFileMetadata(String projectId, String fileId) async {
    await _filesCol(projectId).doc(fileId).delete();
  }

  Stream<List<FileModel>> watchFiles(String projectId) {
    return _filesCol(projectId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => FileModel.fromJson(doc.data()))
            .toList());
  }
}



