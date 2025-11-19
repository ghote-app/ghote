// ChatMessage model for AI chat functionality

class ChatMessage {
  final String id;
  final String projectId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final String? fileId; // 關聯的文件ID（如果訊息基於特定文件）

  const ChatMessage({
    required this.id,
    required this.projectId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.fileId,
  });

  ChatMessage copyWith({
    String? id,
    String? projectId,
    String? role,
    String? content,
    DateTime? timestamp,
    String? fileId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      fileId: fileId ?? this.fileId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'fileId': fileId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fileId: json['fileId'] as String?,
    );
  }
}

