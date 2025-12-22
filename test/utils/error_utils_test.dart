import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/utils/error_utils.dart';

void main() {
  group('ErrorUtils', () {
    group('formatAiError', () {
      test('should format overloaded error', () {
        final result = ErrorUtils.formatAiError('Service overloaded');
        expect(result, contains('AI 服務繁忙中，請稍後再試'));
      });

      test('should format 503 error', () {
        final result = ErrorUtils.formatAiError('Error 503: Service Unavailable');
        expect(result, contains('AI 服務繁忙中，請稍後再試'));
      });

      test('should format quota exceeded error', () {
        final result = ErrorUtils.formatAiError('Quota exceeded');
        expect(result, contains('API 使用次數已達上限，請稍後再試'));
      });

      test('should format rate limit error', () {
        final result = ErrorUtils.formatAiError('Rate limit exceeded');
        expect(result, contains('API 使用次數已達上限，請稍後再試'));
      });

      test('should format 429 error', () {
        final result = ErrorUtils.formatAiError('Error 429');
        expect(result, contains('API 使用次數已達上限，請稍後再試'));
      });

      test('should format API key error', () {
        final result = ErrorUtils.formatAiError('Invalid API key');
        expect(result, contains('API 金鑰無效，請檢查設定'));
      });

      test('should format 401 unauthorized error', () {
        final result = ErrorUtils.formatAiError('Error 401: Unauthorized');
        expect(result, contains('API 金鑰無效，請檢查設定'));
      });

      test('should format network error', () {
        final result = ErrorUtils.formatAiError('Network error occurred');
        expect(result, contains('網路連線失敗，請檢查網路狀態'));
      });

      test('should format connection timeout error', () {
        final result = ErrorUtils.formatAiError('Connection timeout');
        expect(result, contains('網路連線失敗，請檢查網路狀態'));
      });

      test('should format socket exception', () {
        final result = ErrorUtils.formatAiError('SocketException: Connection refused');
        expect(result, contains('網路連線失敗，請檢查網路狀態'));
      });

      test('should format content too long error', () {
        final result = ErrorUtils.formatAiError('Content too long');
        expect(result, contains('內容過長，請嘗試減少文字量'));
      });

      test('should format token limit error', () {
        final result = ErrorUtils.formatAiError('Token limit exceeded');
        expect(result, contains('內容過長，請嘗試減少文字量'));
      });

      test('should format safety blocked error', () {
        final result = ErrorUtils.formatAiError('Content blocked by safety filter');
        expect(result, contains('內容被安全過濾，請調整輸入內容'));
      });

      test('should format 404 not found error', () {
        final result = ErrorUtils.formatAiError('Error 404: Not Found');
        expect(result, contains('找不到指定資源'));
      });

      test('should format 500 server error', () {
        final result = ErrorUtils.formatAiError('Error 500: Internal Server Error');
        expect(result, contains('AI 服務暫時不可用，請稍後再試'));
      });

      test('should format unknown error with default message', () {
        final result = ErrorUtils.formatAiError('Some random unknown error');
        expect(result, contains('AI 生成失敗，請稍後再試'));
      });

      test('should be case insensitive', () {
        final result = ErrorUtils.formatAiError('OVERLOADED');
        expect(result, contains('AI 服務繁忙中，請稍後再試'));
      });
    });

    group('isAiError', () {
      test('should return true for gemini errors', () {
        expect(ErrorUtils.isAiError('Gemini API error'), isTrue);
      });

      test('should return true for API errors', () {
        expect(ErrorUtils.isAiError('API call failed'), isTrue);
      });

      test('should return true for overloaded errors', () {
        expect(ErrorUtils.isAiError('Service overloaded'), isTrue);
      });

      test('should return true for 503 errors', () {
        expect(ErrorUtils.isAiError('Error 503'), isTrue);
      });

      test('should return true for 429 errors', () {
        expect(ErrorUtils.isAiError('Error 429'), isTrue);
      });

      test('should return true for quota errors', () {
        expect(ErrorUtils.isAiError('Quota exceeded'), isTrue);
      });

      test('should return false for non-AI errors', () {
        expect(ErrorUtils.isAiError('File not found'), isFalse);
        expect(ErrorUtils.isAiError('Invalid input'), isFalse);
      });

      test('should be case insensitive', () {
        expect(ErrorUtils.isAiError('GEMINI ERROR'), isTrue);
        expect(ErrorUtils.isAiError('OVERLOADED'), isTrue);
      });
    });
  });
}
