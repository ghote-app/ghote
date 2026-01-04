import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flashcard.dart';
import '../services/gemini_service.dart';
import '../services/project_service.dart';
import '../utils/error_utils.dart';

class FlashcardService {
  final GeminiService _geminiService;
  final ProjectService _projectService;

  FlashcardService({
    GeminiService? geminiService,
    ProjectService? projectService,
  })  : _geminiService = geminiService ?? GeminiService(),
        _projectService = projectService ?? ProjectService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _flashcardsCol(String projectId) =>
      _firestore
          .collection('projects')
          .doc(projectId)
          .collection('flashcards');

  /// 從專案文件生成學習卡
  Future<List<Flashcard>> generateFlashcards({
    required String projectId,
    String? fileId,
    int count = 10,
    String language = 'zh', // 'zh' | 'en'
  }) async {
    try {
      // 獲取目前存在的文件（確保使用最新資料，避免使用已刪除文件）
      final files = await _projectService.watchFiles(projectId).first;
      
      String content;
      if (fileId != null) {
        // 檢查指定文件是否仍然存在
        final file = files.where((f) => f.id == fileId).firstOrNull;
        if (file == null) {
          throw Exception('文件不存在或已被刪除');
        }
        content = file.extractedText ?? '';
        if (content.isEmpty) {
          throw Exception('文件尚未提取文字，請先提取文字');
        }
      } else {
        // 從所有「目前存在且已提取文字」的文件獲取內容
        final validFiles = files.where((f) => 
          f.extractedText != null && 
          f.extractedText!.isNotEmpty &&
          f.extractionStatus == 'extracted'
        ).toList();
        
        if (validFiles.isEmpty) {
          throw Exception('專案中沒有已提取文字的文件');
        }
        
        final StringBuffer buffer = StringBuffer();
        for (final file in validFiles) {
          buffer.writeln('--- ${file.name} ---');
          buffer.writeln(file.extractedText);
          buffer.writeln('');
        }
        content = buffer.toString();
      }

      // 調用 Gemini API 生成學習卡
      final languageInstruction = language == 'en'
          ? 'Generate flashcards in English.'
          : '以繁體中文生成學習卡。';
      final exampleFormat = language == 'en'
          ? '''[
  {
    "question": "Question 1",
    "answer": "Answer 1",
    "difficulty": "medium",
    "tags": ["tag1", "tag2"]
  }
]'''
          : '''[
  {
    "question": "問題1",
    "answer": "答案1",
    "difficulty": "medium",
    "tags": ["標籤1", "標籤2"]
  }
]''';
      
      final prompt = '''
Based on the following content, generate exactly $count flashcards.

$languageInstruction

Each flashcard should include:
1. question: A clear question (front of card)
2. answer: A detailed answer (back of card)
3. difficulty: "easy", "medium", or "hard" based on complexity
4. tags: 2-3 relevant topic tags

Content:
$content

Return in strict JSON format:
$exampleFormat

Only return the JSON array, no other text, markdown formatting, or explanations.
''';

      final response = await _geminiService.generateText(prompt: prompt);
      
      // 解析 JSON 響應
      final flashcards = _parseFlashcardsJson(response, projectId, fileId);
      
      // 保存到 Firestore
      for (final flashcard in flashcards) {
        await _flashcardsCol(projectId).doc(flashcard.id).set(flashcard.toJson());
      }

      return flashcards;
    } catch (e) {
      throw Exception(ErrorUtils.formatAiError(e));
    }
  }

  /// 解析 JSON 響應
  List<Flashcard> _parseFlashcardsJson(
    String jsonResponse,
    String projectId,
    String? fileId,
  ) {
    try {
      // 清理響應（移除 markdown 代碼塊等）
      String cleanJson = jsonResponse.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final List<dynamic> jsonList = jsonDecode(cleanJson);
      final now = DateTime.now();

      return jsonList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        
        // 解析 tags
        List<String> tags = [];
        if (item['tags'] != null) {
          tags = (item['tags'] as List).map((e) => e.toString()).toList();
        }
        
        return Flashcard(
          id: 'fc_${now.microsecondsSinceEpoch}_$index',
          projectId: projectId,
          fileId: fileId,
          question: item['question'] as String? ?? '',
          answer: item['answer'] as String? ?? '',
          difficulty: item['difficulty'] as String? ?? 'medium',
          tags: tags,
          createdAt: now,
        );
      }).toList();
    } catch (e) {
      throw Exception('解析學習卡 JSON 失敗: $e');
    }
  }

  /// 獲取專案的學習卡列表
  Stream<List<Flashcard>> watchFlashcards(String projectId) {
    return _flashcardsCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromJson(doc.data()))
            .toList());
  }

  /// 更新學習卡的複習狀態
  Future<void> updateReviewStatus(
    String projectId,
    String flashcardId, {
    required double masteryLevel,
  }) async {
    try {
      await _flashcardsCol(projectId).doc(flashcardId).update({
        'lastReviewed': DateTime.now().toIso8601String(),
        'reviewCount': FieldValue.increment(1),
        'masteryLevel': masteryLevel,
      });
    } catch (e) {
      throw Exception('更新複習狀態失敗: $e');
    }
  }

  /// 刪除學習卡
  Future<void> deleteFlashcard(String projectId, String flashcardId) async {
    try {
      await _flashcardsCol(projectId).doc(flashcardId).delete();
    } catch (e) {
      throw Exception('刪除學習卡失敗: $e');
    }
  }

  /// 刪除與特定文件關聯的所有學習卡
  Future<int> deleteFlashcardsByFileId(String projectId, String fileId) async {
    try {
      final snapshot = await _flashcardsCol(projectId)
          .where('fileId', isEqualTo: fileId)
          .get();
      
      if (snapshot.docs.isEmpty) return 0;
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('刪除文件相關學習卡失敗: $e');
    }
  }

  /// 切換學習卡收藏狀態
  Future<void> toggleFavorite(
    String projectId,
    String flashcardId,
    bool isFavorite,
  ) async {
    try {
      await _flashcardsCol(projectId).doc(flashcardId).update({
        'isFavorite': isFavorite,
      });
    } catch (e) {
      throw Exception('更新收藏狀態失敗: $e');
    }
  }

  /// FR-8.5 & FR-8.6: 更新卡片標記狀態
  Future<void> updateCardStatus(
    String projectId,
    String flashcardId,
    String status, // 'mastered' | 'review' | 'difficult' | 'unlearned'
  ) async {
    try {
      await _flashcardsCol(projectId).doc(flashcardId).update({
        'status': status,
        'lastReviewed': DateTime.now().toIso8601String(),
        'reviewCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('更新卡片狀態失敗: $e');
    }
  }

  /// FR-8.9: 根據狀態篩選學習卡
  Stream<List<Flashcard>> watchFlashcardsByStatus(String projectId, String status) {
    return _flashcardsCol(projectId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromJson(doc.data()))
            .toList());
  }

  /// FR-9.3: 獲取學習進度統計
  Future<Map<String, int>> getFlashcardStats(String projectId) async {
    try {
      final snapshot = await _flashcardsCol(projectId).get();
      final cards = snapshot.docs.map((doc) => Flashcard.fromJson(doc.data())).toList();
      
      return {
        'total': cards.length,
        'mastered': cards.where((c) => c.status == 'mastered').length,
        'review': cards.where((c) => c.status == 'review').length,
        'difficult': cards.where((c) => c.status == 'difficult').length,
        'unlearned': cards.where((c) => c.status == 'unlearned').length,
      };
    } catch (e) {
      throw Exception('獲取學習統計失敗: $e');
    }
  }

  /// FR-9.3: 獲取學習進度統計 Stream
  Stream<Map<String, int>> watchFlashcardStats(String projectId) {
    return _flashcardsCol(projectId)
        .snapshots()
        .map((snapshot) {
          final cards = snapshot.docs.map((doc) => Flashcard.fromJson(doc.data())).toList();
          return {
            'total': cards.length,
            'mastered': cards.where((c) => c.status == 'mastered').length,
            'review': cards.where((c) => c.status == 'review').length,
            'difficult': cards.where((c) => c.status == 'difficult').length,
            'unlearned': cards.where((c) => c.status == 'unlearned').length,
          };
        });
  }

  /// FR-8.8: 獲取所有標籤
  Future<List<String>> getAllTags(String projectId) async {
    try {
      final snapshot = await _flashcardsCol(projectId).get();
      final Set<String> tags = {};
      for (final doc in snapshot.docs) {
        final card = Flashcard.fromJson(doc.data());
        tags.addAll(card.tags);
      }
      return tags.toList()..sort();
    } catch (e) {
      throw Exception('獲取標籤失敗: $e');
    }
  }

  /// FR-8.8: 根據標籤篩選
  Stream<List<Flashcard>> watchFlashcardsByTag(String projectId, String tag) {
    return _flashcardsCol(projectId)
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromJson(doc.data()))
            .toList());
  }
}

