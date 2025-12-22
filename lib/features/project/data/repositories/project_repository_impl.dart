import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/file_model.dart';
import '../../domain/repositories/project_repository.dart';

/// Implementation of ProjectRepository using Firebase
/// Follows Dependency Inversion Principle - depends on abstraction (ProjectRepository)
class ProjectRepositoryImpl implements ProjectRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  ProjectRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Convert Firestore document to FileModel
  FileModel _docToFileModel(DocumentSnapshot doc, String projectId) {
    final data = doc.data() as Map<String, dynamic>;
    return FileModel.fromJson({
      ...data,
      'id': doc.id,
      'projectId': projectId,
      'uploadedAt': (data['uploadedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'uploaderId': data['uploaderId'] ?? _userId ?? '',
    });
  }

  @override
  Stream<List<FileModel>> watchFiles(String projectId) {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _docToFileModel(doc, projectId))
            .toList());
  }

  @override
  Future<FileModel?> getFile(String projectId, String fileId) async {
    if (_userId == null) return null;
    
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .doc(fileId)
        .get();
    
    if (!doc.exists) return null;
    return _docToFileModel(doc, projectId);
  }

  @override
  Future<FileModel> uploadFile({
    required String projectId,
    required String fileName,
    required String fileType,
    required int sizeBytes,
    required String category,
    required List<int> fileBytes,
    String? localPath,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    // Upload to Firebase Storage
    final storageRef = _storage
        .ref()
        .child('users')
        .child(_userId!)
        .child('projects')
        .child(projectId)
        .child('files')
        .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
    
    final uploadTask = await storageRef.putData(
      Uint8List.fromList(fileBytes),
      SettableMetadata(contentType: _getContentType(fileType)),
    );
    
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    // Save to Firestore
    final fileData = {
      'name': fileName,
      'type': fileType,
      'sizeBytes': sizeBytes,
      'category': category,
      'downloadUrl': downloadUrl,
      'storageType': 'cloud',
      'uploadedAt': FieldValue.serverTimestamp(),
      'extractionStatus': 'pending',
      if (localPath != null) 'localPath': localPath,
    };
    
    final docRef = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .add(fileData);
    
    final newDoc = await docRef.get();
    return _docToFileModel(newDoc, projectId);
  }

  @override
  Future<void> deleteFile(String projectId, String fileId) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    // Get file info first
    final file = await getFile(projectId, fileId);
    
    // Delete from Storage if cloud file
    if (file?.downloadUrl != null) {
      try {
        await _storage.refFromURL(file!.downloadUrl!).delete();
      } catch (e) {
        // Storage file might already be deleted, continue
      }
    }
    
    // Delete from Firestore
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .doc(fileId)
        .delete();
  }

  @override
  Future<void> updateProjectInfo({
    required String projectId,
    required String name,
    String? description,
    String? color,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    final updateData = <String, dynamic>{
      'title': name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (description != null) updateData['description'] = description;
    if (color != null) updateData['color'] = color;
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(projectId)
        .update(updateData);
  }

  @override
  Future<String?> getProjectTitle(String projectId) async {
    if (_userId == null) return null;
    
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(projectId)
        .get();
    
    return doc.data()?['title'] as String?;
  }

  String _getContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
