import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_key_service.dart';

class GeminiService {
  final ApiKeyService _apiKeyService = ApiKeyService();
  final String? _apiKey;

  GeminiService({String? apiKey}) : _apiKey = apiKey;

  Future<String?> _getApiKey() async {
    // 優先使用傳入的 API 金鑰
    if (_apiKey != null) return _apiKey;
    
    // 其次從環境變數讀取
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) return envKey;
    
    // 最後從 SharedPreferences 讀取（用戶設置）
    return await _apiKeyService.getGeminiApiKey();
  }

  /// 獲取 Gemini 模型實例
  Future<GenerativeModel> _getModel({
    String? modelName,
    String? systemInstruction,
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API 金鑰未設置，請在設置中配置');
    }

    final model = modelName ?? 'gemini-2.0-flash';
    return GenerativeModel(
      model: model,
      apiKey: apiKey,
      systemInstruction: systemInstruction != null 
        ? Content.system(systemInstruction) 
        : null,
    );
  }

  /// 發送聊天訊息（流式響應）
  Stream<String> chatStream({
    required String prompt,
    required List<Content> history,
    String? systemInstruction,
    String? modelName,
  }) async* {
    try {
      final model = await _getModel(
        modelName: modelName,
        systemInstruction: systemInstruction,
      );
      
      // 創建聊天會話
      final chat = model.startChat(history: history);

      final response = chat.sendMessageStream(
        Content.text(prompt),
      );

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      throw Exception('Gemini API 錯誤: $e');
    }
  }

  /// 發送單次請求（非流式）
  Future<String> generateText({
    required String prompt,
    String? systemInstruction,
    String? modelName,
  }) async {
    try {
      final model = await _getModel(
        modelName: modelName,
        systemInstruction: systemInstruction,
      );
      final content = Content.text(prompt);
      
      final response = await model.generateContent([content]);

      return response.text ?? '';
    } catch (e) {
      throw Exception('Gemini API 錯誤: $e');
    }
  }

  /// 生成抽認卡
  Future<List<Map<String, String>>> generateFlashcards({
    required String content,
    int count = 10,
  }) async {
    final prompt = '''
基於以下內容，生成 $count 個抽認卡。每個抽認卡包含問題和答案。

內容：
$content

請以 JSON 格式返回，格式如下：
[
  {"question": "問題1", "answer": "答案1"},
  {"question": "問題2", "answer": "答案2"}
]

只返回 JSON 數組，不要包含其他文字。
''';

    try {
      final response = await generateText(prompt: prompt);
      // 解析 JSON 響應
      // 這裡需要實現 JSON 解析邏輯
      // 暫時返回空列表，實際實現時需要解析 JSON
      return [];
    } catch (e) {
      throw Exception('生成抽認卡失敗: $e');
    }
  }

  /// 生成問題
  Future<List<Map<String, dynamic>>> generateQuestions({
    required String content,
    String questionType = 'mcq', // 'mcq' | 'open-ended'
    int count = 5,
  }) async {
    final typeText = questionType == 'mcq' ? '選擇題' : '開放式問題';
    final prompt = '''
基於以下內容，生成 $count 個$typeText。

內容：
$content

${questionType == 'mcq' 
  ? '每個選擇題包含問題、4個選項和正確答案。' 
  : '每個開放式問題包含問題和參考答案。'}

請以 JSON 格式返回，格式如下：
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

只返回 JSON 數組，不要包含其他文字。
''';

    try {
      final response = await generateText(prompt: prompt);
      // 解析 JSON 響應
      // 暫時返回空列表，實際實現時需要解析 JSON
      return [];
    } catch (e) {
      throw Exception('生成問題失敗: $e');
    }
  }
}

