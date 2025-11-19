import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flashcard.dart';
import '../models/file_model.dart';
import '../services/gemini_service.dart';
import '../services/project_service.dart';

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

  /// 從專案文件生成抽認卡
  Future<List<Flashcard>> generateFlashcards({
    required String projectId,
    String? fileId,
    int count = 10,
  }) async {
    try {
      // 獲取文件內容
      String content;
      if (fileId != null) {
        final files = await _projectService.watchFiles(projectId).first;
        final file = files.firstWhere((f) => f.id == fileId);
        content = file.extractedText ?? '';
        if (content.isEmpty) {
          throw Exception('文件尚未提取文字，請先提取文字');
        }
      } else {
        // 從所有文件獲取內容
        final files = await _projectService.watchFiles(projectId).first;
        final StringBuffer buffer = StringBuffer();
        for (final file in files) {
          if (file.extractedText != null && file.extractedText!.isNotEmpty) {
            buffer.writeln('--- ${file.name} ---');
            buffer.writeln(file.extractedText);
            buffer.writeln('');
          }
        }
        content = buffer.toString();
        if (content.isEmpty) {
          throw Exception('專案中沒有已提取文字的文件');
        }
      }

      // 調用 Gemini API 生成抽認卡
      final prompt = '''
基於以下內容，生成 $count 個抽認卡。每個抽認卡應該包含一個清晰的問題和詳細的答案。

內容：
$content

請以嚴格的 JSON 格式返回，格式如下：
[
  {"question": "問題1", "answer": "答案1"},
  {"question": "問題2", "answer": "答案2"}
]

只返回 JSON 數組，不要包含任何其他文字、markdown 格式或解釋。
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
      throw Exception('生成抽認卡失敗: $e');
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
        return Flashcard(
          id: 'fc_${now.microsecondsSinceEpoch}_$index',
          projectId: projectId,
          fileId: fileId,
          question: item['question'] as String? ?? '',
          answer: item['answer'] as String? ?? '',
          createdAt: now,
        );
      }).toList();
    } catch (e) {
      throw Exception('解析抽認卡 JSON 失敗: $e');
    }
  }

  /// 獲取專案的抽認卡列表
  Stream<List<Flashcard>> watchFlashcards(String projectId) {
    return _flashcardsCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromJson(doc.data()))
            .toList());
  }

  /// 更新抽認卡的複習狀態
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

  /// 刪除抽認卡
  Future<void> deleteFlashcard(String projectId, String flashcardId) async {
    try {
      await _flashcardsCol(projectId).doc(flashcardId).delete();
    } catch (e) {
      throw Exception('刪除抽認卡失敗: $e');
    }
  }
}

