import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/chat_message.dart';
import '../models/file_model.dart';
import '../services/gemini_service.dart';
import '../services/project_service.dart';

class ChatService {
  final GeminiService _geminiService;
  final ProjectService _projectService;

  ChatService({
    GeminiService? geminiService,
    ProjectService? projectService,
  })  : _geminiService = geminiService ?? GeminiService(),
        _projectService = projectService ?? ProjectService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesCol(String projectId) =>
      _firestore
          .collection('projects')
          .doc(projectId)
          .collection('chatMessages');

  /// 獲取專案的所有文件提取文字（用於構建上下文）
  Future<String> _buildProjectContext(String projectId) async {
    try {
      final files = await _projectService.watchFiles(projectId).first;
      final StringBuffer contextBuffer = StringBuffer();

      for (final file in files) {
        if (file.extractedText != null && file.extractedText!.isNotEmpty) {
          contextBuffer.writeln('--- 文件: ${file.name} ---');
          contextBuffer.writeln(file.extractedText);
          contextBuffer.writeln('');
        }
      }

      return contextBuffer.toString();
    } catch (e) {
      return '';
    }
  }

  /// 構建系統提示詞（優先使用專案內容）
  Future<String> _buildSystemInstruction(String projectId) async {
    final context = await _buildProjectContext(projectId);
    
    if (context.isEmpty) {
      return '你是一個友善的 AI 學習助手。幫助用戶解答問題和學習。';
    }

    return '''你是一個友善的 AI 學習助手。以下是用戶專案中的文件內容，請優先基於這些內容回答問題。如果問題與這些內容無關，你可以使用你的通用知識回答。

專案文件內容：
$context

請基於以上內容優先回答問題，如果內容中沒有相關信息，再使用你的通用知識。''';
  }

  /// 發送聊天訊息（流式響應）
  Stream<String> sendMessage({
    required String projectId,
    required String userMessage,
  }) async* {
    try {
      // 保存用戶訊息
      final userMsg = ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        role: 'user',
        content: userMessage,
        timestamp: DateTime.now(),
      );
      await _messagesCol(projectId).doc(userMsg.id).set(userMsg.toJson());

      // 獲取聊天歷史
      final history = await _getChatHistory(projectId);

      // 構建系統提示詞
      final systemInstruction = await _buildSystemInstruction(projectId);

      // 發送到 Gemini
      final responseBuffer = StringBuffer();
      await for (final chunk in _geminiService.chatStream(
        prompt: userMessage,
        history: history,
        systemInstruction: systemInstruction,
      )) {
        responseBuffer.write(chunk);
        yield chunk;
      }

      // 保存 AI 回應
      final aiMsg = ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        role: 'assistant',
        content: responseBuffer.toString(),
        timestamp: DateTime.now(),
      );
      await _messagesCol(projectId).doc(aiMsg.id).set(aiMsg.toJson());
    } catch (e) {
      throw Exception('發送訊息失敗: $e');
    }
  }

  /// 獲取聊天歷史（轉換為 Gemini Content 格式）
  Future<List<Content>> _getChatHistory(String projectId) async {
    try {
      final snapshot = await _messagesCol(projectId)
          .orderBy('timestamp', descending: false)
          .limit(20) // 限制歷史訊息數量
          .get();

      return snapshot.docs.map((doc) {
        final msg = ChatMessage.fromJson(doc.data());
        return Content.text(msg.content);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// 獲取聊天訊息流
  Stream<List<ChatMessage>> watchMessages(String projectId) {
    return _messagesCol(projectId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList());
  }

  /// 清除聊天歷史
  Future<void> clearChatHistory(String projectId) async {
    try {
      final snapshot = await _messagesCol(projectId).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('清除聊天歷史失敗: $e');
    }
  }
}

