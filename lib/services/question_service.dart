import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/question.dart';
import '../services/gemini_service.dart';
import '../services/project_service.dart';
import '../utils/error_utils.dart';

class QuestionService {
  final GeminiService _geminiService;
  final ProjectService _projectService;

  QuestionService({
    GeminiService? geminiService,
    ProjectService? projectService,
  })  : _geminiService = geminiService ?? GeminiService(),
        _projectService = projectService ?? ProjectService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _questionsCol(String projectId) =>
      _firestore
          .collection('projects')
          .doc(projectId)
          .collection('questions');

  /// 從專案文件生成問題
  Future<List<Question>> generateQuestions({
    required String projectId,
    String? fileId,
    String questionType = 'mcq-single', // 'mcq-single' | 'mcq-multiple' | 'open-ended'
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

      // 調用 Gemini API 生成問題
      final languageInstruction = language == 'en'
          ? 'Generate questions in English.'
          : '以繁體中文生成問題。';
      
      String typeText;
      String requirementText;
      String exampleFormat;
      
      // 向後兼容：將 'mcq' 視為 'mcq-single'
      final normalizedType = questionType == 'mcq' ? 'mcq-single' : questionType;
      
      if (normalizedType == 'mcq-single') {
        typeText = language == 'en' ? 'single-choice questions' : '單選題';
        requirementText = language == 'en'
            ? 'Each question should include: question, 4 options (A/B/C/D), one correct answer, explanation, and difficulty (easy/medium/hard).'
            : '每個單選題應包含：問題、4個選項（A/B/C/D）、一個正確答案、解釋、難度（easy/medium/hard）。';
        exampleFormat = language == 'en'
            ? '''[\n  {\n    "question": "Question 1",\n    "options": ["Option A", "Option B", "Option C", "Option D"],\n    "correctAnswer": "Option A",\n    "explanation": "Explanation",\n    "difficulty": "medium"\n  }\n]'''
            : '''[\n  {\n    "question": "問題1",\n    "options": ["選項A", "選項B", "選項C", "選項D"],\n    "correctAnswer": "選項A",\n    "explanation": "解釋",\n    "difficulty": "medium"\n  }\n]''';
      } else if (normalizedType == 'mcq-multiple') {
        typeText = language == 'en' ? 'multiple-choice questions (select all that apply)' : '多選題';
        requirementText = language == 'en'
            ? 'Each question should include: question, 4-5 options (A/B/C/D/E), multiple correct answers (2-3), explanation, and difficulty (easy/medium/hard).'
            : '每個多選題應包含：問題、4-5個選項（A/B/C/D/E）、多個正確答案（2-3個）、解釋、難度（easy/medium/hard）。';
        exampleFormat = language == 'en'
            ? '''[\n  {\n    "question": "Which of the following are correct? (Select all that apply)",\n    "options": ["Option A", "Option B", "Option C", "Option D"],\n    "correctAnswers": ["Option A", "Option C"],\n    "explanation": "Explanation",\n    "difficulty": "medium"\n  }\n]'''
            : '''[\n  {\n    "question": "以下哪些是正確的？（可多選）",\n    "options": ["選項A", "選項B", "選項C", "選項D"],\n    "correctAnswers": ["選項A", "選項C"],\n    "explanation": "解釋",\n    "difficulty": "medium"\n  }\n]''';
      } else {
        typeText = language == 'en' ? 'open-ended questions' : '開放式問答題';
        requirementText = language == 'en'
            ? 'Each question should include: question, reference answer, keywords (3-5 key terms), explanation, and difficulty (easy/medium/hard).'
            : '每個開放式問題應包含：問題、參考答案、關鍵字（3-5個）、解釋、難度（easy/medium/hard）。';
        exampleFormat = language == 'en'
            ? '''[\n  {\n    "question": "Question 1",\n    "answer": "Reference answer 1",\n    "keywords": ["keyword1", "keyword2", "keyword3"],\n    "explanation": "Explanation",\n    "difficulty": "medium"\n  }\n]'''
            : '''[\n  {\n    "question": "問題1",\n    "answer": "參考答案1",\n    "keywords": ["關鍵字1", "關鍵字2", "關鍵字3"],\n    "explanation": "解釋",\n    "difficulty": "medium"\n  }\n]''';
      }
      
      final prompt = '''
Based on the following content, generate $count $typeText.

$languageInstruction

Content:
$content

$requirementText

Return in strict JSON format:
$exampleFormat

Only return the JSON array, no other text, markdown formatting, or explanations.
''';

      final response = await _geminiService.generateText(prompt: prompt);
      
      // 解析 JSON 響應
      final questions = _parseQuestionsJson(response, projectId, fileId, normalizedType);
      
      // 保存到 Firestore
      for (final question in questions) {
        await _questionsCol(projectId).doc(question.id).set(question.toJson());
      }

      return questions;
    } catch (e) {
      throw Exception(ErrorUtils.formatAiError(e));
    }
  }

  /// 解析 JSON 響應
  List<Question> _parseQuestionsJson(
    String jsonResponse,
    String projectId,
    String? fileId,
    String questionType,
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
        final difficulty = item['difficulty'] as String? ?? 'medium';
        
        if (questionType == 'mcq-single' || questionType == 'mcq') {
          return Question(
            id: 'q_mcq_s_${now.microsecondsSinceEpoch}_$index',
            projectId: projectId,
            fileId: fileId,
            questionText: item['question'] as String? ?? '',
            questionType: 'mcq-single',
            options: item['options'] != null
                ? (item['options'] as List).map((e) => e.toString()).toList()
                : null,
            correctAnswer: item['correctAnswer'] as String?,
            explanation: item['explanation'] as String?,
            difficulty: difficulty,
            createdAt: now,
          );
        } else if (questionType == 'mcq-multiple') {
          // 處理多選題的正確答案
          List<String>? correctAnswers;
          if (item['correctAnswers'] != null) {
            correctAnswers = (item['correctAnswers'] as List)
                .map((e) => e.toString())
                .toList();
          }
          return Question(
            id: 'q_mcq_m_${now.microsecondsSinceEpoch}_$index',
            projectId: projectId,
            fileId: fileId,
            questionText: item['question'] as String? ?? '',
            questionType: 'mcq-multiple',
            options: item['options'] != null
                ? (item['options'] as List).map((e) => e.toString()).toList()
                : null,
            correctAnswers: correctAnswers,
            explanation: item['explanation'] as String?,
            difficulty: difficulty,
            createdAt: now,
          );
        } else {
          // 開放式問題
          List<String>? keywords;
          if (item['keywords'] != null) {
            keywords = (item['keywords'] as List)
                .map((e) => e.toString())
                .toList();
          }
          return Question(
            id: 'q_open_${now.microsecondsSinceEpoch}_$index',
            projectId: projectId,
            fileId: fileId,
            questionText: item['question'] as String? ?? '',
            questionType: 'open-ended',
            correctAnswer: item['answer'] as String?,
            explanation: item['explanation'] as String?,
            keywords: keywords,
            difficulty: difficulty,
            createdAt: now,
          );
        }
      }).toList();
    } catch (e) {
      throw Exception('解析問題 JSON 失敗: $e');
    }
  }

  /// 獲取專案的問題列表
  Stream<List<Question>> watchQuestions(String projectId) {
    return _questionsCol(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Question.fromJson(doc.data()))
            .toList());
  }

  /// 刪除問題
  Future<void> deleteQuestion(String projectId, String questionId) async {
    try {
      await _questionsCol(projectId).doc(questionId).delete();
    } catch (e) {
      throw Exception('刪除問題失敗: $e');
    }
  }

  /// 刪除與特定文件關聯的所有問題
  Future<int> deleteQuestionsByFileId(String projectId, String fileId) async {
    try {
      final snapshot = await _questionsCol(projectId)
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
      throw Exception('刪除文件相關問題失敗: $e');
    }
  }
}

