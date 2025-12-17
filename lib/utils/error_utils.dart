/// 錯誤訊息格式化工具
class ErrorUtils {
  /// 開啟調試模式（顯示原始錯誤訊息）
  static const bool _debugMode = true;

  /// 將技術性錯誤轉換為用戶友好的中文訊息
  static String formatAiError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    final originalError = error.toString();
    
    String friendlyMessage;

    // 模型過載
    if (errorStr.contains('overloaded') || errorStr.contains('503') || errorStr.contains('service unavailable')) {
      friendlyMessage = 'AI 服務繁忙中，請稍後再試';
    }
    // 配額超限
    else if (errorStr.contains('quota') || errorStr.contains('rate limit') || errorStr.contains('429')) {
      friendlyMessage = 'API 使用次數已達上限，請稍後再試';
    }
    // API 金鑰問題
    else if (errorStr.contains('api key') || errorStr.contains('invalid key') || errorStr.contains('401') || errorStr.contains('unauthorized')) {
      friendlyMessage = 'API 金鑰無效，請檢查設定';
    }
    // 網路問題
    else if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('timeout') || errorStr.contains('socketexception')) {
      friendlyMessage = '網路連線失敗，請檢查網路狀態';
    }
    // 內容過長
    else if (errorStr.contains('too long') || errorStr.contains('token') || errorStr.contains('context length')) {
      friendlyMessage = '內容過長，請嘗試減少文字量';
    }
    // 安全過濾
    else if (errorStr.contains('safety') || errorStr.contains('blocked') || errorStr.contains('harmful')) {
      friendlyMessage = '內容被安全過濾，請調整輸入內容';
    }
    // 資源未找到
    else if (errorStr.contains('not found') || errorStr.contains('404')) {
      friendlyMessage = '找不到指定資源';
    }
    // 伺服器錯誤
    else if (errorStr.contains('500') || errorStr.contains('internal server')) {
      friendlyMessage = 'AI 服務暫時不可用，請稍後再試';
    }
    // 其他錯誤
    else {
      friendlyMessage = 'AI 生成失敗，請稍後再試';
    }

    // 調試模式：在友善訊息前顯示原始錯誤
    if (_debugMode) {
      return '[$originalError]\n$friendlyMessage';
    }
    
    return friendlyMessage;
  }

  /// 檢查錯誤是否為 AI 相關錯誤
  static bool isAiError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('gemini') || 
           errorStr.contains('api') ||
           errorStr.contains('overloaded') ||
           errorStr.contains('503') ||
           errorStr.contains('429') ||
           errorStr.contains('quota');
  }
}
