import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/chat_message.dart';

void main() {
  group('ChatMessage Model', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('Creation', () {
      test('should create ChatMessage with required parameters', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'Hello, AI!',
          timestamp: testDate,
        );

        expect(message.id, 'msg1');
        expect(message.projectId, 'proj1');
        expect(message.role, 'user');
        expect(message.content, 'Hello, AI!');
        expect(message.timestamp, testDate);
        expect(message.fileId, isNull);
      });

      test('should create user message', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'What is Flutter?',
          timestamp: testDate,
        );

        expect(message.role, 'user');
      });

      test('should create assistant message', () {
        final message = ChatMessage(
          id: 'msg2',
          projectId: 'proj1',
          role: 'assistant',
          content: 'Flutter is a UI framework.',
          timestamp: testDate,
        );

        expect(message.role, 'assistant');
      });

      test('should create message with file association', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'Explain this document',
          timestamp: testDate,
          fileId: 'file123',
        );

        expect(message.fileId, 'file123');
      });

      test('should allow empty content', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: '',
          timestamp: testDate,
        );

        expect(message.content, '');
      });

      test('should allow very long content', () {
        final longContent = 'A' * 10000;
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'assistant',
          content: longContent,
          timestamp: testDate,
        );

        expect(message.content.length, 10000);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'Original content',
          timestamp: testDate,
        );

        final copied = original.copyWith(
          content: 'Updated content',
          role: 'assistant',
        );

        expect(copied.content, 'Updated content');
        expect(copied.role, 'assistant');
        expect(copied.id, 'msg1');
        expect(copied.projectId, 'proj1');
        expect(copied.timestamp, testDate);
      });

      test('should preserve original values when not specified', () {
        final original = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'Test message',
          timestamp: testDate,
          fileId: 'file123',
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.projectId, original.projectId);
        expect(copied.role, original.role);
        expect(copied.content, original.content);
        expect(copied.timestamp, original.timestamp);
        expect(copied.fileId, original.fileId);
      });

      test('should update timestamp', () {
        final original = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'Test',
          timestamp: testDate,
        );

        final newTimestamp = testDate.add(const Duration(hours: 1));
        final copied = original.copyWith(timestamp: newTimestamp);

        expect(copied.timestamp, newTimestamp);
      });
    });

    group('JSON Serialization', () {
      test('toJson should convert ChatMessage to Map', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'Hello, world!',
          timestamp: testDate,
          fileId: 'file123',
        );

        final json = message.toJson();

        expect(json['id'], 'msg1');
        expect(json['projectId'], 'proj1');
        expect(json['role'], 'user');
        expect(json['content'], 'Hello, world!');
        expect(json['timestamp'], testDate.toIso8601String());
        expect(json['fileId'], 'file123');
      });

      test('toJson should handle null fileId', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'assistant',
          content: 'Response',
          timestamp: testDate,
        );

        final json = message.toJson();

        expect(json['fileId'], isNull);
      });

      test('fromJson should create ChatMessage from Map', () {
        final json = {
          'id': 'msg1',
          'projectId': 'proj1',
          'role': 'user',
          'content': 'Test message',
          'timestamp': testDate.toIso8601String(),
          'fileId': 'file123',
        };

        final message = ChatMessage.fromJson(json);

        expect(message.id, 'msg1');
        expect(message.projectId, 'proj1');
        expect(message.role, 'user');
        expect(message.content, 'Test message');
        expect(message.timestamp, testDate);
        expect(message.fileId, 'file123');
      });

      test('fromJson should handle null fileId', () {
        final json = {
          'id': 'msg1',
          'projectId': 'proj1',
          'role': 'assistant',
          'content': 'Response',
          'timestamp': testDate.toIso8601String(),
        };

        final message = ChatMessage.fromJson(json);

        expect(message.fileId, isNull);
      });

      test('JSON round trip should preserve all data', () {
        final original = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'This is a test message with special chars: 中文 émojis 🎉',
          timestamp: testDate,
          fileId: 'file123',
        );

        final json = original.toJson();
        final restored = ChatMessage.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.projectId, original.projectId);
        expect(restored.role, original.role);
        expect(restored.content, original.content);
        expect(restored.timestamp, original.timestamp);
        expect(restored.fileId, original.fileId);
      });

      test('JSON round trip should preserve multiline content', () {
        final original = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'assistant',
          content: 'Line 1\nLine 2\nLine 3',
          timestamp: testDate,
        );

        final json = original.toJson();
        final restored = ChatMessage.fromJson(json);

        expect(restored.content, original.content);
      });
    });

    group('Edge Cases', () {
      test('should handle special characters in content', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: '特殊字符 <>&"\' \n\t',
          timestamp: testDate,
        );

        expect(message.content, '特殊字符 <>&"\' \n\t');
      });

      test('should handle emoji in content', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'user',
          content: 'Hello! 👋 How are you? 😊',
          timestamp: testDate,
        );

        expect(message.content, contains('👋'));
        expect(message.content, contains('😊'));
      });

      test('should handle code blocks in content', () {
        final message = ChatMessage(
          id: 'msg1',
          projectId: 'proj1',
          role: 'assistant',
          content: '''
```dart
void main() {
  print('Hello, World!');
}
```
          ''',
          timestamp: testDate,
        );

        expect(message.content, contains('void main()'));
      });
    });
  });
}
