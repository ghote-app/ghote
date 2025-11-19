// Question model for practice questions

class Question {
  final String id;
  final String projectId;
  final String? fileId; // 關聯的文件ID
  final String questionText;
  final String questionType; // 'mcq' | 'open-ended'
  final List<String>? options; // 僅用於 MCQ
  final String? correctAnswer; // 正確答案
  final String? explanation; // 解釋
  final DateTime createdAt;
  final String difficulty; // 'easy' | 'medium' | 'hard'

  const Question({
    required this.id,
    required this.projectId,
    this.fileId,
    required this.questionText,
    required this.questionType,
    this.options,
    this.correctAnswer,
    this.explanation,
    required this.createdAt,
    this.difficulty = 'medium',
  });

  bool get isMcq => questionType == 'mcq';
  bool get isOpenEnded => questionType == 'open-ended';

  Question copyWith({
    String? id,
    String? projectId,
    String? fileId,
    String? questionText,
    String? questionType,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    DateTime? createdAt,
    String? difficulty,
  }) {
    return Question(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fileId: fileId ?? this.fileId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'fileId': fileId,
      'questionText': questionText,
      'questionType': questionType,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      fileId: json['fileId'] as String?,
      questionText: json['questionText'] as String,
      questionType: json['questionType'] as String,
      options: json['options'] != null
          ? (json['options'] as List).map((e) => e as String).toList()
          : null,
      correctAnswer: json['correctAnswer'] as String?,
      explanation: json['explanation'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }
}

