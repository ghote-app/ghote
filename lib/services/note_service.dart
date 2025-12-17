import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import '../services/gemini_service.dart';
import '../services/project_service.dart';
import '../utils/error_utils.dart';

class NoteService {
  final GeminiService _geminiService;
  final ProjectService _projectService;

  NoteService({
    GeminiService? geminiService,
    ProjectService? projectService,
  })  : _geminiService = geminiService ?? GeminiService(),
        _projectService = projectService ?? ProjectService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesCol(String projectId) =>
      _firestore
          .collection('projects')
          .doc(projectId)
          .collection('notes');

  /// 從專案文件生成重點筆記
  Future<List<Note>> generateNotes({
    required String projectId,
    String? fileId,
    int count = 5,
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

      // 調用 Gemini API 生成重點筆記
      final languageInstruction = language == 'en'
          ? 'Generate study notes in English.'
          : '以繁體中文生成重點筆記。';
      
      final exampleFormat = language == 'en'
          ? '''[
  {
    "title": "Note Title",
    "mainConcepts": ["Concept 1", "Concept 2", "Concept 3"],
    "detailedExplanation": "Detailed explanation of the topic...",
    "importance": "high",
    "keywords": ["keyword1", "keyword2", "keyword3"]
  }
]'''
          : '''[
  {
    "title": "筆記標題",
    "mainConcepts": ["概念1", "概念2", "概念3"],
    "detailedExplanation": "主題的詳細說明...",
    "importance": "high",
    "keywords": ["關鍵字1", "關鍵字2", "關鍵字3"]
  }
]''';
      
      final prompt = '''
Based on the following content, generate exactly $count key study notes.

$languageInstruction

Each note should include:
1. title: A clear and concise title summarizing the topic
2. mainConcepts: 2-5 main concepts or key points (as an array)
3. detailedExplanation: A comprehensive explanation (100-300 words)
4. importance: "high", "medium", or "low" based on the topic's significance
5. keywords: 3-5 important keywords for this topic (as an array)

Content:
$content

Return in strict JSON format:
$exampleFormat

Only return the JSON array, no other text, markdown formatting, or explanations.
''';

      final response = await _geminiService.generateText(prompt: prompt);
      
      // 解析 JSON 響應
      final notes = _parseNotesJson(response, projectId, fileId);
      
      // 保存到 Firestore
      for (final note in notes) {
        await _notesCol(projectId).doc(note.id).set(note.toJson());
      }

      return notes;
    } catch (e) {
      throw Exception(ErrorUtils.formatAiError(e));
    }
  }

  /// 解析 JSON 響應
  List<Note> _parseNotesJson(
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
        
        // 解析 mainConcepts
        List<String> mainConcepts = [];
        if (item['mainConcepts'] != null) {
          mainConcepts = (item['mainConcepts'] as List)
              .map((e) => e.toString())
              .toList();
        }
        
        // 解析 keywords
        List<String> keywords = [];
        if (item['keywords'] != null) {
          keywords = (item['keywords'] as List)
              .map((e) => e.toString())
              .toList();
        }
        
        return Note(
          id: 'note_${now.microsecondsSinceEpoch}_$index',
          projectId: projectId,
          fileId: fileId,
          title: item['title'] as String? ?? '未命名筆記',
          mainConcepts: mainConcepts,
          detailedExplanation: item['detailedExplanation'] as String? ?? '',
          importance: item['importance'] as String? ?? 'medium',
          keywords: keywords,
          createdAt: now,
        );
      }).toList();
    } catch (e) {
      throw Exception('解析重點筆記 JSON 失敗: $e');
    }
  }

  /// 獲取專案的重點筆記列表
  Stream<List<Note>> watchNotes(String projectId) {
    return _notesCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromJson(doc.data()))
            .toList());
  }

  /// 獲取單一筆記
  Future<Note?> getNote(String projectId, String noteId) async {
    try {
      final doc = await _notesCol(projectId).doc(noteId).get();
      if (!doc.exists) return null;
      return Note.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('獲取筆記失敗: $e');
    }
  }

  /// 刪除筆記
  Future<void> deleteNote(String projectId, String noteId) async {
    try {
      await _notesCol(projectId).doc(noteId).delete();
    } catch (e) {
      throw Exception('刪除筆記失敗: $e');
    }
  }

  /// 刪除與特定文件關聯的所有筆記
  Future<int> deleteNotesByFileId(String projectId, String fileId) async {
    try {
      final snapshot = await _notesCol(projectId)
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
      throw Exception('刪除文件相關筆記失敗: $e');
    }
  }

  /// 切換筆記收藏狀態
  Future<void> toggleFavorite(
    String projectId,
    String noteId,
    bool isFavorite,
  ) async {
    try {
      await _notesCol(projectId).doc(noteId).update({
        'isFavorite': isFavorite,
      });
    } catch (e) {
      throw Exception('更新收藏狀態失敗: $e');
    }
  }

  /// 刪除專案所有筆記
  Future<void> deleteAllNotes(String projectId) async {
    try {
      final snapshot = await _notesCol(projectId).get();
      if (snapshot.docs.isEmpty) return;
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('刪除所有筆記失敗: $e');
    }
  }
}
