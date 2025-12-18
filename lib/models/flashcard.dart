// Flashcard model for spaced repetition learning
// FR-8: 抽認卡學習功能

class Flashcard {
  final String id;
  final String projectId;
  final String? fileId; // 關聯的文件ID
  final String question;
  final String answer;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final List<String> tags; // 標籤 (FR-8.8)
  final DateTime createdAt;
  final DateTime? lastReviewed; // FR-9.5: 最後查看時間
  final int reviewCount;
  final double masteryLevel; // 0.0 - 1.0
  final bool isFavorite; // 是否收藏
  final String status; // FR-8.5: 'unlearned' | 'mastered' | 'review' | 'difficult'

  const Flashcard({
    required this.id,
    required this.projectId,
    this.fileId,
    required this.question,
    required this.answer,
    this.difficulty = 'medium',
    this.tags = const [],
    required this.createdAt,
    this.lastReviewed,
    this.reviewCount = 0,
    this.masteryLevel = 0.0,
    this.isFavorite = false,
    this.status = 'unlearned', // FR-8.5: 預設未學習
  });

  /// 難度對應的顯示文字
  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return '簡單';
      case 'medium':
        return '中等';
      case 'hard':
        return '困難';
      default:
        return '中等';
    }
  }

  /// FR-8.5: 狀態對應的顯示文字
  String get statusLabel {
    switch (status) {
      case 'mastered':
        return '已掌握';
      case 'review':
        return '需複習';
      case 'difficult':
        return '困難';
      case 'unlearned':
      default:
        return '未學習';
    }
  }

  /// FR-8.5: 狀態對應的顏色
  static int getStatusColor(String status) {
    switch (status) {
      case 'mastered':
        return 0xFF4CAF50; // Green
      case 'review':
        return 0xFFFF9800; // Orange
      case 'difficult':
        return 0xFFF44336; // Red
      case 'unlearned':
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  Flashcard copyWith({
    String? id,
    String? projectId,
    String? fileId,
    String? question,
    String? answer,
    String? difficulty,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    double? masteryLevel,
    bool? isFavorite,
    String? status,
  }) {
    return Flashcard(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fileId: fileId ?? this.fileId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'fileId': fileId,
      'question': question,
      'answer': answer,
      'difficulty': difficulty,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'reviewCount': reviewCount,
      'masteryLevel': masteryLevel,
      'isFavorite': isFavorite,
      'status': status,
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      fileId: json['fileId'] as String?,
      question: json['question'] as String,
      answer: json['answer'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      tags: json['tags'] != null
          ? (json['tags'] as List).map((e) => e as String).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      masteryLevel: (json['masteryLevel'] as num?)?.toDouble() ?? 0.0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      status: json['status'] as String? ?? 'unlearned',
    );
  }
}

