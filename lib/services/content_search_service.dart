import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flashcard.dart';
import '../models/question.dart';
import '../models/note.dart';

/// FR-10 內容查詢與篩選服務
class ContentSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== FR-10.1 & FR-10.2: 內容類型統計 ====================

  /// 獲取專案中所有內容類型的統計
  Future<ContentStats> getContentStats(String projectId) async {
    final flashcardsCount = await _getCollectionCount(projectId, 'flashcards');
    final questionsCount = await _getCollectionCount(projectId, 'questions');
    final notesCount = await _getCollectionCount(projectId, 'notes');
    
    // 獲取各類型題目數量
    final mcqSingleCount = await _getQuestionsCountByType(projectId, 'mcq-single');
    final mcqMultipleCount = await _getQuestionsCountByType(projectId, 'mcq-multiple');
    final openEndedCount = await _getQuestionsCountByType(projectId, 'open-ended');

    return ContentStats(
      flashcardsCount: flashcardsCount,
      questionsCount: questionsCount,
      notesCount: notesCount,
      mcqSingleCount: mcqSingleCount,
      mcqMultipleCount: mcqMultipleCount,
      openEndedCount: openEndedCount,
    );
  }

  /// 獲取特定文件生成的所有內容統計
  Future<ContentStats> getFileContentStats(String projectId, String fileId) async {
    final flashcardsCount = await _getCollectionCountByFile(projectId, 'flashcards', fileId);
    final questionsCount = await _getCollectionCountByFile(projectId, 'questions', fileId);
    final notesCount = await _getCollectionCountByFile(projectId, 'notes', fileId);
    
    final mcqSingleCount = await _getQuestionsCountByTypeAndFile(projectId, 'mcq-single', fileId);
    final mcqMultipleCount = await _getQuestionsCountByTypeAndFile(projectId, 'mcq-multiple', fileId);
    final openEndedCount = await _getQuestionsCountByTypeAndFile(projectId, 'open-ended', fileId);

    return ContentStats(
      flashcardsCount: flashcardsCount,
      questionsCount: questionsCount,
      notesCount: notesCount,
      mcqSingleCount: mcqSingleCount,
      mcqMultipleCount: mcqMultipleCount,
      openEndedCount: openEndedCount,
    );
  }

  Future<int> _getCollectionCount(String projectId, String collection) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection(collection)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getCollectionCountByFile(String projectId, String collection, String fileId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection(collection)
        .where('fileId', isEqualTo: fileId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getQuestionsCountByType(String projectId, String questionType) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('questions')
        .where('questionType', isEqualTo: questionType)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getQuestionsCountByTypeAndFile(String projectId, String questionType, String fileId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('questions')
        .where('questionType', isEqualTo: questionType)
        .where('fileId', isEqualTo: fileId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ==================== FR-10.3: 難度篩選 ====================

  /// 根據難度篩選抽認卡
  Stream<List<Flashcard>> watchFlashcardsByDifficulty(
    String projectId, {
    String? difficulty, // 'easy' | 'medium' | 'hard' | null (所有)
    String? fileId,
  }) {
    // 獲取所有抽認卡，然後在客戶端進行篩選和排序
    // 這樣可以避免 Firestore 複合索引的需求
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('flashcards')
        .snapshots()
        .map((snapshot) {
          var flashcards = snapshot.docs
              .map((doc) => Flashcard.fromJson(doc.data()))
              .toList();
          
          // 客戶端篩選
          if (difficulty != null) {
            flashcards = flashcards.where((f) => f.difficulty == difficulty).toList();
          }
          if (fileId != null) {
            flashcards = flashcards.where((f) => f.fileId == fileId).toList();
          }
          
          // 客戶端排序（最新的在前面）
          flashcards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return flashcards;
        });
  }

  /// 根據難度篩選題目
  Stream<List<Question>> watchQuestionsByDifficulty(
    String projectId, {
    String? difficulty,
    String? questionType,
    String? fileId,
  }) {
    // 獲取所有題目，然後在客戶端進行篩選和排序
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('questions')
        .snapshots()
        .map((snapshot) {
          var questions = snapshot.docs
              .map((doc) => Question.fromJson(doc.data()))
              .toList();
          
          // 客戶端篩選
          if (difficulty != null) {
            questions = questions.where((q) => q.difficulty == difficulty).toList();
          }
          if (questionType != null) {
            questions = questions.where((q) => q.questionType == questionType).toList();
          }
          if (fileId != null) {
            questions = questions.where((q) => q.fileId == fileId).toList();
          }
          
          // 客戶端排序（最新的在前面）
          questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return questions;
        });
  }

  // ==================== FR-10.4: 標籤篩選 ====================

  /// 獲取專案中所有標籤
  Future<List<String>> getAllTags(String projectId) async {
    final Set<String> tags = {};
    
    // 從抽認卡獲取標籤
    final flashcardsSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('flashcards')
        .get();
    
    for (final doc in flashcardsSnapshot.docs) {
      final tagsList = doc.data()['tags'] as List<dynamic>?;
      if (tagsList != null) {
        tags.addAll(tagsList.map((e) => e.toString()));
      }
    }

    // 從筆記獲取關鍵字作為標籤
    final notesSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('notes')
        .get();
    
    for (final doc in notesSnapshot.docs) {
      final keywords = doc.data()['keywords'] as List<dynamic>?;
      if (keywords != null) {
        tags.addAll(keywords.map((e) => e.toString()));
      }
    }

    // 從題目獲取關鍵字
    final questionsSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('questions')
        .get();
    
    for (final doc in questionsSnapshot.docs) {
      final keywords = doc.data()['keywords'] as List<dynamic>?;
      if (keywords != null) {
        tags.addAll(keywords.map((e) => e.toString()));
      }
    }

    return tags.toList()..sort();
  }

  /// 根據標籤篩選抽認卡
  Stream<List<Flashcard>> watchFlashcardsByTag(String projectId, String tag) {
    // 使用客戶端篩選避免索引問題
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('flashcards')
        .snapshots()
        .map((snapshot) {
          var flashcards = snapshot.docs
              .map((doc) => Flashcard.fromJson(doc.data()))
              .where((f) => f.tags.contains(tag))
              .toList();
          
          // 客戶端排序
          flashcards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return flashcards;
        });
  }

  /// 根據關鍵字篩選筆記
  Stream<List<Note>> watchNotesByKeyword(String projectId, String keyword) {
    // 使用客戶端篩選避免索引問題
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('notes')
        .snapshots()
        .map((snapshot) {
          var notes = snapshot.docs
              .map((doc) => Note.fromJson(doc.data()))
              .where((n) => n.keywords.contains(keyword))
              .toList();
          
          // 客戶端排序
          notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notes;
        });
  }

  // ==================== FR-10.5: 跨文件內容搜尋 ====================

  /// 搜尋專案中的所有內容
  Future<SearchResults> searchContent(
    String projectId,
    String query, {
    bool searchFlashcards = true,
    bool searchQuestions = true,
    bool searchNotes = true,
  }) async {
    final queryLower = query.toLowerCase();
    List<Flashcard> flashcards = [];
    List<Question> questions = [];
    List<Note> notes = [];

    if (searchFlashcards) {
      final flashcardsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('flashcards')
          .get();
      
      flashcards = flashcardsSnapshot.docs
          .map((doc) => Flashcard.fromJson(doc.data()))
          .where((f) =>
              f.question.toLowerCase().contains(queryLower) ||
              f.answer.toLowerCase().contains(queryLower) ||
              f.tags.any((t) => t.toLowerCase().contains(queryLower)))
          .toList();
    }

    if (searchQuestions) {
      final questionsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('questions')
          .get();
      
      questions = questionsSnapshot.docs
          .map((doc) => Question.fromJson(doc.data()))
          .where((q) =>
              q.questionText.toLowerCase().contains(queryLower) ||
              (q.correctAnswer?.toLowerCase().contains(queryLower) ?? false) ||
              (q.explanation?.toLowerCase().contains(queryLower) ?? false) ||
              (q.options?.any((o) => o.toLowerCase().contains(queryLower)) ?? false))
          .toList();
    }

    if (searchNotes) {
      final notesSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('notes')
          .get();
      
      notes = notesSnapshot.docs
          .map((doc) => Note.fromJson(doc.data()))
          .where((n) =>
              n.title.toLowerCase().contains(queryLower) ||
              n.detailedExplanation.toLowerCase().contains(queryLower) ||
              n.mainConcepts.any((c) => c.toLowerCase().contains(queryLower)) ||
              n.keywords.any((k) => k.toLowerCase().contains(queryLower)))
          .toList();
    }

    return SearchResults(
      flashcards: flashcards,
      questions: questions,
      notes: notes,
      query: query,
    );
  }

  /// 獲取文件相關的所有內容
  Future<FileContents> getFileContents(String projectId, String fileId) async {
    final flashcardsSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('flashcards')
        .where('fileId', isEqualTo: fileId)
        .orderBy('createdAt', descending: true)
        .get();
    
    final questionsSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('questions')
        .where('fileId', isEqualTo: fileId)
        .orderBy('createdAt', descending: true)
        .get();
    
    final notesSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('notes')
        .where('fileId', isEqualTo: fileId)
        .orderBy('createdAt', descending: true)
        .get();

    return FileContents(
      fileId: fileId,
      flashcards: flashcardsSnapshot.docs
          .map((doc) => Flashcard.fromJson(doc.data()))
          .toList(),
      questions: questionsSnapshot.docs
          .map((doc) => Question.fromJson(doc.data()))
          .toList(),
      notes: notesSnapshot.docs
          .map((doc) => Note.fromJson(doc.data()))
          .toList(),
    );
  }
}

/// 內容統計
class ContentStats {
  final int flashcardsCount;
  final int questionsCount;
  final int notesCount;
  final int mcqSingleCount;
  final int mcqMultipleCount;
  final int openEndedCount;

  const ContentStats({
    required this.flashcardsCount,
    required this.questionsCount,
    required this.notesCount,
    required this.mcqSingleCount,
    required this.mcqMultipleCount,
    required this.openEndedCount,
  });

  int get totalCount => flashcardsCount + questionsCount + notesCount;
}

/// 搜尋結果
class SearchResults {
  final List<Flashcard> flashcards;
  final List<Question> questions;
  final List<Note> notes;
  final String query;

  const SearchResults({
    required this.flashcards,
    required this.questions,
    required this.notes,
    required this.query,
  });

  int get totalCount => flashcards.length + questions.length + notes.length;
  bool get isEmpty => totalCount == 0;
}

/// 文件內容
class FileContents {
  final String fileId;
  final List<Flashcard> flashcards;
  final List<Question> questions;
  final List<Note> notes;

  const FileContents({
    required this.fileId,
    required this.flashcards,
    required this.questions,
    required this.notes,
  });

  int get totalCount => flashcards.length + questions.length + notes.length;
  bool get isEmpty => totalCount == 0;
}
