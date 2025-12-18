import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../models/flashcard.dart';
import '../models/question.dart';
import '../models/note.dart';

/// FR-11 資料同步與快取服務
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncing = false;
  
  // 同步狀態回調
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // ==================== 初始化 ====================

  /// 初始化同步服務
  Future<void> initialize() async {
    // 監聽網路狀態變化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // 檢查初始網路狀態
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    // 如果在線，嘗試同步待處理的資料
    if (_isOnline) {
      await syncPendingData();
    }
  }

  /// 處理網路狀態變化
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    // FR-11.3: 網路恢復時自動上傳本地學習進度
    if (!wasOnline && _isOnline) {
      debugPrint('網路恢復，開始同步待處理資料...');
      _syncStatusController.add(SyncStatus(
        status: SyncState.syncing,
        message: '網路恢復，正在同步資料...',
      ));
      await syncPendingData();
    } else if (wasOnline && !_isOnline) {
      debugPrint('網路離線，切換到離線模式');
      _syncStatusController.add(SyncStatus(
        status: SyncState.offline,
        message: '目前離線，資料將在網路恢復時同步',
      ));
    }
  }

  /// 關閉服務
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }

  // ==================== FR-11.1: 自動同步到雲端 ====================

  /// 同步專案資料到雲端
  Future<void> syncProjectData(String projectId) async {
    if (!_isOnline) {
      debugPrint('離線狀態，無法同步到雲端');
      return;
    }

    try {
      _syncStatusController.add(SyncStatus(
        status: SyncState.syncing,
        message: '正在同步專案資料...',
      ));

      // 獲取本地快取的待同步資料
      final prefs = await SharedPreferences.getInstance();
      final pendingKey = 'pending_sync_$projectId';
      final pendingJson = prefs.getString(pendingKey);
      
      if (pendingJson != null) {
        final pendingData = jsonDecode(pendingJson) as Map<String, dynamic>;
        
        // 同步學習進度
        if (pendingData.containsKey('learningProgress')) {
          await _syncLearningProgress(projectId, pendingData['learningProgress']);
        }

        // 同步抽認卡狀態
        if (pendingData.containsKey('flashcardStatus')) {
          await _syncFlashcardStatus(projectId, pendingData['flashcardStatus']);
        }

        // 清除已同步的資料
        await prefs.remove(pendingKey);
      }

      _syncStatusController.add(SyncStatus(
        status: SyncState.synced,
        message: '同步完成',
        lastSyncTime: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('同步失敗: $e');
      _syncStatusController.add(SyncStatus(
        status: SyncState.error,
        message: '同步失敗: $e',
      ));
    }
  }

  Future<void> _syncLearningProgress(String projectId, Map<String, dynamic> progressData) async {
    final docRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('learningProgress')
        .doc('current');
    
    await docRef.set(progressData, SetOptions(merge: true));
  }

  Future<void> _syncFlashcardStatus(String projectId, Map<String, dynamic> statusData) async {
    final batch = _firestore.batch();
    
    statusData.forEach((flashcardId, status) {
      final docRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('flashcards')
          .doc(flashcardId);
      batch.update(docRef, {'status': status});
    });

    await batch.commit();
  }

  // ==================== FR-11.2: 本地快取 ====================

  /// 快取專案內容供離線查閱
  Future<void> cacheProjectContent(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 快取抽認卡
      final flashcardsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('flashcards')
          .get();
      final flashcards = flashcardsSnapshot.docs.map((d) => d.data()).toList();
      await prefs.setString(
        'cache_flashcards_$projectId',
        jsonEncode(flashcards),
      );

      // 快取題目
      final questionsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('questions')
          .get();
      final questions = questionsSnapshot.docs.map((d) => d.data()).toList();
      await prefs.setString(
        'cache_questions_$projectId',
        jsonEncode(questions),
      );

      // 快取筆記
      final notesSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('notes')
          .get();
      final notes = notesSnapshot.docs.map((d) => d.data()).toList();
      await prefs.setString(
        'cache_notes_$projectId',
        jsonEncode(notes),
      );

      // 記錄快取時間
      await prefs.setString(
        'cache_time_$projectId',
        DateTime.now().toIso8601String(),
      );

      debugPrint('專案 $projectId 內容已快取');
    } catch (e) {
      debugPrint('快取失敗: $e');
    }
  }

  /// 獲取快取的抽認卡
  Future<List<Flashcard>> getCachedFlashcards(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cache_flashcards_$projectId');
      
      if (cachedJson != null) {
        final List<dynamic> list = jsonDecode(cachedJson);
        return list.map((e) => Flashcard.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('讀取快取失敗: $e');
    }
    return [];
  }

  /// 獲取快取的題目
  Future<List<Question>> getCachedQuestions(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cache_questions_$projectId');
      
      if (cachedJson != null) {
        final List<dynamic> list = jsonDecode(cachedJson);
        return list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('讀取快取失敗: $e');
    }
    return [];
  }

  /// 獲取快取的筆記
  Future<List<Note>> getCachedNotes(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cache_notes_$projectId');
      
      if (cachedJson != null) {
        final List<dynamic> list = jsonDecode(cachedJson);
        return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('讀取快取失敗: $e');
    }
    return [];
  }

  /// 獲取快取時間
  Future<DateTime?> getCacheTime(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('cache_time_$projectId');
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  /// 清除專案快取
  Future<void> clearProjectCache(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_flashcards_$projectId');
    await prefs.remove('cache_questions_$projectId');
    await prefs.remove('cache_notes_$projectId');
    await prefs.remove('cache_time_$projectId');
  }

  // ==================== FR-11.3: 離線學習進度記錄 ====================

  /// 記錄離線學習進度（稍後同步）
  Future<void> recordOfflineLearningProgress(
    String projectId, {
    int? flashcardsStudied,
    int? questionsAttempted,
    int? correctAnswers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingKey = 'pending_sync_$projectId';
    
    Map<String, dynamic> pendingData = {};
    final existingJson = prefs.getString(pendingKey);
    if (existingJson != null) {
      pendingData = jsonDecode(existingJson) as Map<String, dynamic>;
    }

    // 合併學習進度
    Map<String, dynamic> progress = pendingData['learningProgress'] ?? {};
    if (flashcardsStudied != null) {
      progress['flashcardsStudied'] = (progress['flashcardsStudied'] ?? 0) + flashcardsStudied;
    }
    if (questionsAttempted != null) {
      progress['questionsAttempted'] = (progress['questionsAttempted'] ?? 0) + questionsAttempted;
    }
    if (correctAnswers != null) {
      progress['correctAnswers'] = (progress['correctAnswers'] ?? 0) + correctAnswers;
    }
    progress['lastUpdated'] = DateTime.now().toIso8601String();
    
    pendingData['learningProgress'] = progress;
    await prefs.setString(pendingKey, jsonEncode(pendingData));

    // 如果在線，立即同步
    if (_isOnline) {
      await syncProjectData(projectId);
    }
  }

  /// 記錄離線抽認卡狀態更新
  Future<void> recordOfflineFlashcardStatus(
    String projectId,
    String flashcardId,
    String status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingKey = 'pending_sync_$projectId';
    
    Map<String, dynamic> pendingData = {};
    final existingJson = prefs.getString(pendingKey);
    if (existingJson != null) {
      pendingData = jsonDecode(existingJson) as Map<String, dynamic>;
    }

    Map<String, dynamic> flashcardStatus = pendingData['flashcardStatus'] ?? {};
    flashcardStatus[flashcardId] = status;
    
    pendingData['flashcardStatus'] = flashcardStatus;
    await prefs.setString(pendingKey, jsonEncode(pendingData));

    // 如果在線，立即同步
    if (_isOnline) {
      await syncProjectData(projectId);
    }
  }

  // ==================== FR-11.4: 手動同步 ====================

  /// 同步所有待處理的資料
  Future<SyncResult> syncPendingData() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: '同步正在進行中');
    }

    if (!_isOnline) {
      return SyncResult(success: false, message: '目前離線，無法同步');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus(
      status: SyncState.syncing,
      message: '正在同步資料...',
    ));

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('pending_sync_'));
      
      int syncedCount = 0;
      for (final key in keys) {
        final projectId = key.replaceFirst('pending_sync_', '');
        await syncProjectData(projectId);
        syncedCount++;
      }

      _isSyncing = false;
      _syncStatusController.add(SyncStatus(
        status: SyncState.synced,
        message: '同步完成',
        lastSyncTime: DateTime.now(),
      ));

      return SyncResult(
        success: true,
        message: syncedCount > 0 ? '成功同步 $syncedCount 個專案' : '無待同步資料',
        syncedCount: syncedCount,
      );
    } catch (e) {
      _isSyncing = false;
      _syncStatusController.add(SyncStatus(
        status: SyncState.error,
        message: '同步失敗: $e',
      ));
      return SyncResult(success: false, message: '同步失敗: $e');
    }
  }

  /// 手動觸發完整同步（包含下載最新資料）
  Future<SyncResult> fullSync(String projectId) async {
    if (!_isOnline) {
      return SyncResult(success: false, message: '目前離線，無法同步');
    }

    _syncStatusController.add(SyncStatus(
      status: SyncState.syncing,
      message: '正在執行完整同步...',
    ));

    try {
      // 1. 先上傳待同步的離線資料
      await syncProjectData(projectId);

      // 2. 重新快取最新資料
      await cacheProjectContent(projectId);

      _syncStatusController.add(SyncStatus(
        status: SyncState.synced,
        message: '完整同步完成',
        lastSyncTime: DateTime.now(),
      ));

      return SyncResult(success: true, message: '完整同步完成');
    } catch (e) {
      _syncStatusController.add(SyncStatus(
        status: SyncState.error,
        message: '同步失敗: $e',
      ));
      return SyncResult(success: false, message: '同步失敗: $e');
    }
  }

  /// 獲取目前網路狀態
  bool get isOnline => _isOnline;

  /// 檢查是否有待同步的資料
  Future<bool> hasPendingData(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('pending_sync_$projectId');
  }

  /// 獲取待同步資料數量
  Future<int> getPendingDataCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith('pending_sync_')).length;
  }
}

/// 同步狀態
enum SyncState {
  idle,
  syncing,
  synced,
  offline,
  error,
}

/// 同步狀態資訊
class SyncStatus {
  final SyncState status;
  final String message;
  final DateTime? lastSyncTime;

  const SyncStatus({
    required this.status,
    required this.message,
    this.lastSyncTime,
  });
}

/// 同步結果
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  const SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });
}
