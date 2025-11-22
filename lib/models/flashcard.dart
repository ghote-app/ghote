// Flashcard model for spaced repetition learning

class Flashcard {
  final String id;
  final String projectId;
  final String? fileId; // 關聯的文件ID
  final String question;
  final String answer;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final DateTime createdAt;
  final DateTime? lastReviewed;
  final int reviewCount;
  final double masteryLevel; // 0.0 - 1.0
  final bool isFavorite; // 是否收藏

  const Flashcard({
    required this.id,
    required this.projectId,
    this.fileId,
    required this.question,
    required this.answer,
    this.difficulty = 'medium',
    required this.createdAt,
    this.lastReviewed,
    this.reviewCount = 0,
    this.masteryLevel = 0.0,
    this.isFavorite = false,
  });

  Flashcard copyWith({
    String? id,
    String? projectId,
    String? fileId,
    String? question,
    String? answer,
    String? difficulty,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    double? masteryLevel,
    bool? isFavorite,
  }) {
    return Flashcard(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fileId: fileId ?? this.fileId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      isFavorite: isFavorite ?? this.isFavorite,
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
      'createdAt': createdAt.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'reviewCount': reviewCount,
      'masteryLevel': masteryLevel,
      'isFavorite': isFavorite,
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      masteryLevel: (json['masteryLevel'] as num?)?.toDouble() ?? 0.0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

