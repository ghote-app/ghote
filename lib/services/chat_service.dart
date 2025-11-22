import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/chat_message.dart';
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
    
    const baseInstruction = '''你是一位熱情且富有同理心的「學習教練」。
    是屬於這個Ghote APP的一個聊天機器人。
    說明時說明你是Ghote創造的智能助手。

你的核心使命是：
1. 以耐心和清晰的繁體中文語言，解構複雜的專案文件內容。
2. 鼓勵用戶提出問題，即使是基礎問題，也要給予正向回饋。
3. 嘗試用簡單的比喻或實際例子來幫助用戶理解概念。
4. 在每次回答後，主動詢問用戶是否有其他相關疑問，以促進對話。
5. 優先基於文件內容回答問題，如果內容不相關才使用通用知識。

回答格式要求：
- 使用純文字格式回答
- 不要使用 ** 或 __ 來標示粗體
- 不要使用 * 或 - 來建立列表
- 不要使用 # 來建立標題
- 不要使用反引號 ` 來標示程式碼
- 使用自然的文字排版，用換行和縮排來組織內容
- 如需強調，可以使用「」或 [] 符號
- 如需列舉，使用數字或中文序號（一、二、三）

請始終保持親切、友善和鼓勵的語氣，讓用戶感到被支持和理解。
請務必遵守回答格式要求''';
    
    if (context.isEmpty) {
      return baseInstruction;
    }

    return '''$baseInstruction

以下是用戶專案中的文件內容，請優先基於這些內容回答問題：

專案文件內容：
$context

記得：優先使用以上文件內容回答，若問題與文件無關，再運用你的通用知識協助用戶。''';
  }

  /// 發送聊天訊息（流式響應）
  Stream<String> sendMessage({
    required String projectId,
    required String userMessage,
    List<DataPart>? imageParts,
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
        imageParts: imageParts,
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

