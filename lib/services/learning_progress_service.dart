import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/learning_progress.dart';

/// FR-9 學習進度追蹤服務
/// FR-9.1: 記錄學習狀態
/// FR-9.2: 追蹤選擇題正確率
/// FR-9.3: 統計學習卡學習進度
/// FR-9.4: Project 詳情頁面查看整體學習進度
/// FR-9.5: 記錄最後查看時間
class LearningProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  /// 取得學習進度集合參考
  CollectionReference<Map<String, dynamic>> _progressCollection() {
    return _firestore.collection('learning_progress');
  }

  /// 取得或建立 project 的學習進度文檔 ID
  String _getProgressDocId(String projectId) {
    return '${_userId}_$projectId';
  }

  /// FR-9.4: 取得專案的學習進度
  Future<LearningProgress?> getProgress(String projectId) async {
    if (_userId.isEmpty) return null;
    
    final docId = _getProgressDocId(projectId);
    final doc = await _progressCollection().doc(docId).get();
    
    if (!doc.exists) {
      return null;
    }
    
    return LearningProgress.fromJson(doc.data()!, doc.id);
  }

  /// FR-9.4: 監聽專案的學習進度
  Stream<LearningProgress?> watchProgress(String projectId) {
    if (_userId.isEmpty) {
      return Stream.value(null);
    }
    
    final docId = _getProgressDocId(projectId);
    return _progressCollection()
        .doc(docId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return LearningProgress.fromJson(doc.data()!, doc.id);
        });
  }

  /// 建立或取得學習進度
  Future<LearningProgress> getOrCreateProgress(String projectId) async {
    if (_userId.isEmpty) {
      throw Exception('用戶未登入');
    }
    
    final existing = await getProgress(projectId);
    if (existing != null) {
      return existing;
    }
    
    // 建立新的學習進度
    final docId = _getProgressDocId(projectId);
    final progress = LearningProgress(
      id: docId,
      projectId: projectId,
      userId: _userId,
    );
    
    await _progressCollection().doc(docId).set(progress.toJson());
    return progress;
  }

  /// FR-9.1 & FR-9.3: 更新學習卡學習統計
  Future<void> updateFlashcardStats({
    required String projectId,
    required int totalFlashcards,
    required int masteredFlashcards,
    required int reviewFlashcards,
    required int difficultFlashcards,
    required int unlearnedFlashcards,
  }) async {
    if (_userId.isEmpty) return;
    
    final docId = _getProgressDocId(projectId);
    
    await _progressCollection().doc(docId).set({
      'projectId': projectId,
      'userId': _userId,
      'totalFlashcards': totalFlashcards,
      'masteredFlashcards': masteredFlashcards,
      'reviewFlashcards': reviewFlashcards,
      'difficultFlashcards': difficultFlashcards,
      'unlearnedFlashcards': unlearnedFlashcards,
      'lastFlashcardStudyAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// FR-9.2: 記錄測驗結果
  Future<void> recordQuizAttempt({
    required String projectId,
    required int correctCount,
    required int totalQuestions,
  }) async {
    if (_userId.isEmpty) return;
    
    final docId = _getProgressDocId(projectId);
    
    // 使用 increment 來累加數據
    await _progressCollection().doc(docId).set({
      'projectId': projectId,
      'userId': _userId,
      'totalQuizAttempts': FieldValue.increment(totalQuestions),
      'correctAnswers': FieldValue.increment(correctCount),
      'incorrectAnswers': FieldValue.increment(totalQuestions - correctCount),
      'lastQuizAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// FR-9.5: 更新最後查看時間
  Future<void> updateLastViewedAt(String projectId) async {
    if (_userId.isEmpty) return;
    
    final docId = _getProgressDocId(projectId);
    
    await _progressCollection().doc(docId).set({
      'projectId': projectId,
      'userId': _userId,
      'lastViewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 取得用戶所有專案的學習進度
  Future<List<LearningProgress>> getAllProgress() async {
    if (_userId.isEmpty) return [];
    
    final snapshot = await _progressCollection()
        .where('userId', isEqualTo: _userId)
        .orderBy('lastViewedAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => LearningProgress.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// 監聽用戶所有專案的學習進度
  Stream<List<LearningProgress>> watchAllProgress() {
    if (_userId.isEmpty) {
      return Stream.value([]);
    }
    
    return _progressCollection()
        .where('userId', isEqualTo: _userId)
        .orderBy('lastViewedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LearningProgress.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  /// 重置專案的測驗統計
  Future<void> resetQuizStats(String projectId) async {
    if (_userId.isEmpty) return;
    
    final docId = _getProgressDocId(projectId);
    
    await _progressCollection().doc(docId).update({
      'totalQuizAttempts': 0,
      'correctAnswers': 0,
      'incorrectAnswers': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 刪除專案的學習進度
  Future<void> deleteProgress(String projectId) async {
    if (_userId.isEmpty) return;
    
    final docId = _getProgressDocId(projectId);
    await _progressCollection().doc(docId).delete();
  }
}
