import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _geminiApiKeyKey = 'gemini_api_key';

  /// 獲取 Gemini API 金鑰
  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKeyKey);
  }

  /// 保存 Gemini API 金鑰
  Future<void> setGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyKey, apiKey);
  }

  /// 清除 Gemini API 金鑰
  Future<void> clearGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiApiKeyKey);
  }
}

