// Question model for practice questions

class Question {
  final String id;
  final String projectId;
  final String? fileId; // 關聯的文件ID
  final String questionText;
  final String questionType; // 'mcq-single' | 'mcq-multiple' | 'open-ended'
  final List<String>? options; // 僅用於 MCQ
  final String? correctAnswer; // 正確答案（單選）
  final List<String>? correctAnswers; // 正確答案（多選）
  final String? explanation; // 解釋
  final DateTime createdAt;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final List<String>? keywords; // 關鍵字（開放式問題）

  const Question({
    required this.id,
    required this.projectId,
    this.fileId,
    required this.questionText,
    required this.questionType,
    this.options,
    this.correctAnswer,
    this.correctAnswers,
    this.explanation,
    required this.createdAt,
    this.difficulty = 'medium',
    this.keywords,
  });

  bool get isMcq => questionType == 'mcq' || questionType == 'mcq-single' || questionType == 'mcq-multiple';
  bool get isMcqSingle => questionType == 'mcq' || questionType == 'mcq-single';
  bool get isMcqMultiple => questionType == 'mcq-multiple';
  bool get isOpenEnded => questionType == 'open-ended';

  Question copyWith({
    String? id,
    String? projectId,
    String? fileId,
    String? questionText,
    String? questionType,
    List<String>? options,
    String? correctAnswer,
    List<String>? correctAnswers,
    String? explanation,
    DateTime? createdAt,
    String? difficulty,
    List<String>? keywords,
  }) {
    return Question(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fileId: fileId ?? this.fileId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      keywords: keywords ?? this.keywords,
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
      'correctAnswers': correctAnswers,
      'explanation': explanation,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty,
      'keywords': keywords,
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
      correctAnswers: json['correctAnswers'] != null
          ? (json['correctAnswers'] as List).map((e) => e as String).toList()
          : null,
      explanation: json['explanation'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      difficulty: json['difficulty'] as String? ?? 'medium',
      keywords: json['keywords'] != null
          ? (json['keywords'] as List).map((e) => e as String).toList()
          : null,
    );
  }

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
}

