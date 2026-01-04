import 'package:cloud_firestore/cloud_firestore.dart';

/// FR-9 學習進度追蹤
/// FR-9.1: 記錄學習狀態
/// FR-9.2: 追蹤選擇題正確率
/// FR-9.3: 統計學習卡學習進度
/// FR-9.4: Project 詳情頁面查看整體學習進度
/// FR-9.5: 記錄最後查看時間
class LearningProgress {
  final String id;
  final String projectId;
  final String userId;
  
  // FR-9.1: 學習狀態
  final int totalFlashcards;
  final int masteredFlashcards;
  final int reviewFlashcards;
  final int difficultFlashcards;
  final int unlearnedFlashcards;
  
  // FR-9.2: 選擇題正確率
  final int totalQuizAttempts;
  final int correctAnswers;
  final int incorrectAnswers;
  
  // FR-9.5: 最後查看時間
  final DateTime lastViewedAt;
  final DateTime? lastQuizAt;
  final DateTime? lastFlashcardStudyAt;
  
  // 更新時間
  final DateTime updatedAt;
  final DateTime createdAt;

  LearningProgress({
    required this.id,
    required this.projectId,
    required this.userId,
    this.totalFlashcards = 0,
    this.masteredFlashcards = 0,
    this.reviewFlashcards = 0,
    this.difficultFlashcards = 0,
    this.unlearnedFlashcards = 0,
    this.totalQuizAttempts = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    DateTime? lastViewedAt,
    this.lastQuizAt,
    this.lastFlashcardStudyAt,
    DateTime? updatedAt,
    DateTime? createdAt,
  })  : lastViewedAt = lastViewedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// FR-9.2: 計算選擇題正確率
  double get quizAccuracy {
    if (totalQuizAttempts == 0) return 0.0;
    return correctAnswers / totalQuizAttempts;
  }

  /// FR-9.2: 取得正確率百分比字串
  String get quizAccuracyPercent {
    return '${(quizAccuracy * 100).toStringAsFixed(1)}%';
  }

  /// FR-9.3: 計算學習卡學習進度
  double get flashcardProgress {
    if (totalFlashcards == 0) return 0.0;
    return masteredFlashcards / totalFlashcards;
  }

  /// FR-9.3: 取得學習卡進度百分比字串
  String get flashcardProgressPercent {
    return '${(flashcardProgress * 100).toStringAsFixed(1)}%';
  }

  /// 計算整體學習進度（結合學習卡和測驗）
  double get overallProgress {
    // 學習卡進度佔 60%，測驗正確率佔 40%
    return (flashcardProgress * 0.6) + (quizAccuracy * 0.4);
  }

  /// 取得整體進度百分比字串
  String get overallProgressPercent {
    return '${(overallProgress * 100).toStringAsFixed(1)}%';
  }

  /// 取得已學習的學習卡數量（不包含未學習）
  int get learnedFlashcards {
    return masteredFlashcards + reviewFlashcards + difficultFlashcards;
  }

  LearningProgress copyWith({
    String? id,
    String? projectId,
    String? userId,
    int? totalFlashcards,
    int? masteredFlashcards,
    int? reviewFlashcards,
    int? difficultFlashcards,
    int? unlearnedFlashcards,
    int? totalQuizAttempts,
    int? correctAnswers,
    int? incorrectAnswers,
    DateTime? lastViewedAt,
    DateTime? lastQuizAt,
    DateTime? lastFlashcardStudyAt,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return LearningProgress(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      totalFlashcards: totalFlashcards ?? this.totalFlashcards,
      masteredFlashcards: masteredFlashcards ?? this.masteredFlashcards,
      reviewFlashcards: reviewFlashcards ?? this.reviewFlashcards,
      difficultFlashcards: difficultFlashcards ?? this.difficultFlashcards,
      unlearnedFlashcards: unlearnedFlashcards ?? this.unlearnedFlashcards,
      totalQuizAttempts: totalQuizAttempts ?? this.totalQuizAttempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      lastQuizAt: lastQuizAt ?? this.lastQuizAt,
      lastFlashcardStudyAt: lastFlashcardStudyAt ?? this.lastFlashcardStudyAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'userId': userId,
      'totalFlashcards': totalFlashcards,
      'masteredFlashcards': masteredFlashcards,
      'reviewFlashcards': reviewFlashcards,
      'difficultFlashcards': difficultFlashcards,
      'unlearnedFlashcards': unlearnedFlashcards,
      'totalQuizAttempts': totalQuizAttempts,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'lastViewedAt': Timestamp.fromDate(lastViewedAt),
      'lastQuizAt': lastQuizAt != null ? Timestamp.fromDate(lastQuizAt!) : null,
      'lastFlashcardStudyAt': lastFlashcardStudyAt != null
          ? Timestamp.fromDate(lastFlashcardStudyAt!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory LearningProgress.fromJson(Map<String, dynamic> json, String id) {
    return LearningProgress(
      id: id,
      projectId: json['projectId'] ?? '',
      userId: json['userId'] ?? '',
      totalFlashcards: json['totalFlashcards'] ?? 0,
      masteredFlashcards: json['masteredFlashcards'] ?? 0,
      reviewFlashcards: json['reviewFlashcards'] ?? 0,
      difficultFlashcards: json['difficultFlashcards'] ?? 0,
      unlearnedFlashcards: json['unlearnedFlashcards'] ?? 0,
      totalQuizAttempts: json['totalQuizAttempts'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      incorrectAnswers: json['incorrectAnswers'] ?? 0,
      lastViewedAt: json['lastViewedAt'] != null
          ? (json['lastViewedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastQuizAt: json['lastQuizAt'] != null
          ? (json['lastQuizAt'] as Timestamp).toDate()
          : null,
      lastFlashcardStudyAt: json['lastFlashcardStudyAt'] != null
          ? (json['lastFlashcardStudyAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LearningProgress(projectId: $projectId, flashcardProgress: $flashcardProgressPercent, quizAccuracy: $quizAccuracyPercent)';
  }
}
