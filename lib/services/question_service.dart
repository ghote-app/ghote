import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/question.dart';
import '../models/file_model.dart';
import '../services/gemini_service.dart';
import '../services/project_service.dart';

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
    String questionType = 'mcq', // 'mcq' | 'open-ended'
    int count = 5,
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

      // 調用 Gemini API 生成問題
      final typeText = questionType == 'mcq' ? '選擇題' : '開放式問題';
      final prompt = '''
基於以下內容，生成 $count 個$typeText。

內容：
$content

${questionType == 'mcq' 
  ? '每個選擇題應包含：問題、4個選項（A/B/C/D）、正確答案和解釋。' 
  : '每個開放式問題應包含：問題、參考答案和解釋。'}

請以嚴格的 JSON 格式返回，格式如下：
${questionType == 'mcq'
  ? '''[
  {
    "question": "問題1",
    "options": ["選項A", "選項B", "選項C", "選項D"],
    "correctAnswer": "選項A",
    "explanation": "解釋"
  }
]'''
  : '''[
  {
    "question": "問題1",
    "answer": "參考答案1",
    "explanation": "解釋"
  }
]'''}

只返回 JSON 數組，不要包含任何其他文字、markdown 格式或解釋。
''';

      final response = await _geminiService.generateText(prompt: prompt);
      
      // 解析 JSON 響應
      final questions = _parseQuestionsJson(response, projectId, fileId, questionType);
      
      // 保存到 Firestore
      for (final question in questions) {
        await _questionsCol(projectId).doc(question.id).set(question.toJson());
      }

      return questions;
    } catch (e) {
      throw Exception('生成問題失敗: $e');
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
        
        if (questionType == 'mcq') {
          return Question(
            id: 'q_mcq_${now.microsecondsSinceEpoch}_$index',
            projectId: projectId,
            fileId: fileId,
            questionText: item['question'] as String? ?? '',
            questionType: 'mcq',
            options: item['options'] != null
                ? (item['options'] as List).map((e) => e.toString()).toList()
                : null,
            correctAnswer: item['correctAnswer'] as String?,
            explanation: item['explanation'] as String?,
            createdAt: now,
          );
        } else {
          return Question(
            id: 'q_open_${now.microsecondsSinceEpoch}_$index',
            projectId: projectId,
            fileId: fileId,
            questionText: item['question'] as String? ?? '',
            questionType: 'open-ended',
            correctAnswer: item['answer'] as String?,
            explanation: item['explanation'] as String?,
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
}

