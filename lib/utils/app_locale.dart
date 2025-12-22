import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app languages
enum AppLanguage { en, zhTW }

/// Global locale controller for language switching
class AppLocaleController extends ChangeNotifier {
  static const String _prefKey = 'app_language';
  static AppLocaleController? _instance;
  
  AppLanguage _language = AppLanguage.en;
  bool _initialized = false;
  
  AppLanguage get language => _language;
  bool get initialized => _initialized;
  
  /// Singleton instance
  factory AppLocaleController() {
    _instance ??= AppLocaleController._internal();
    return _instance!;
  }
  
  AppLocaleController._internal();
  
  /// Initialize with saved preference or device locale
  Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    
    if (saved != null) {
      _language = saved == 'zh' ? AppLanguage.zhTW : AppLanguage.en;
    } else {
      // Detect device language
      final locale = PlatformDispatcher.instance.locale;
      _language = locale.languageCode == 'zh' ? AppLanguage.zhTW : AppLanguage.en;
    }
    
    _initialized = true;
    notifyListeners();
  }
  
  /// Change language and persist
  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang == AppLanguage.zhTW ? 'zh' : 'en');
    notifyListeners();
  }
  
  /// Toggle between EN and ZH
  Future<void> toggle() async {
    await setLanguage(_language == AppLanguage.en ? AppLanguage.zhTW : AppLanguage.en);
  }
}

/// Global instance
final appLocale = AppLocaleController();

/// Translation helper function
String tr(String key) {
  final lang = appLocale.language;
  final map = _strings[key];
  if (map == null) return key;
  return lang == AppLanguage.en ? (map['en'] ?? key) : (map['zh'] ?? key);
}

/// All app strings with translations
final Map<String, Map<String, String>> _strings = {
  // Common
  'app.name': {'en': 'Ghote', 'zh': 'Ghote'},
  'common.cancel': {'en': 'Cancel', 'zh': '取消'},
  'common.confirm': {'en': 'Confirm', 'zh': '確認'},
  'common.save': {'en': 'Save', 'zh': '儲存'},
  'common.delete': {'en': 'Delete', 'zh': '刪除'},
  'common.edit': {'en': 'Edit', 'zh': '編輯'},
  'common.ok': {'en': 'OK', 'zh': '確定'},
  'common.retry': {'en': 'Retry', 'zh': '重試'},
  'common.loading': {'en': 'Loading...', 'zh': '載入中...'},
  'common.error': {'en': 'Error', 'zh': '錯誤'},
  'common.success': {'en': 'Success', 'zh': '成功'},
  
  // Dashboard
  'dashboard.title': {'en': 'Dashboard', 'zh': '專案總覽'},
  'dashboard.projects': {'en': 'Projects', 'zh': '專案'},
  'dashboard.active': {'en': 'Active', 'zh': '進行中'},
  'dashboard.completed': {'en': 'Completed', 'zh': '已完成'},
  'dashboard.archived': {'en': 'Archived', 'zh': '已封存'},
  'dashboard.all': {'en': 'All', 'zh': '全部'},
  'dashboard.noProjects': {'en': 'No projects yet', 'zh': '尚無專案'},
  'dashboard.createFirst': {'en': 'Create your first project to get started', 'zh': '建立您的第一個專案開始使用'},
  'dashboard.createProject': {'en': 'Create Project', 'zh': '建立專案'},
  'dashboard.uploadFiles': {'en': 'Upload files to project', 'zh': '上傳檔案到專案'},
  'dashboard.search': {'en': 'Search projects...', 'zh': '搜尋專案...'},
  'dashboard.welcomeBack': {'en': 'Welcome back,', 'zh': '歡迎回來，'},
  
  // Project Create Dialog
  'project.create': {'en': 'Create Project', 'zh': '建立專案'},
  'project.title': {'en': 'Project Title', 'zh': '專案名稱'},
  'project.titleHint': {'en': 'Enter project title', 'zh': '輸入專案名稱'},
  'project.description': {'en': 'Description (Optional)', 'zh': '描述（選填）'},
  'project.descriptionHint': {'en': 'Enter project description', 'zh': '輸入專案描述'},
  'project.category': {'en': 'Category (Optional)', 'zh': '分類（選填）'},
  'project.categoryHint': {'en': 'e.g., Study, Work, Personal', 'zh': '例如：學習、工作、個人'},
  'project.colorTag': {'en': 'Color Tag', 'zh': '顏色標籤'},
  'project.status': {'en': 'Status', 'zh': '狀態'},
  
  // Project Details
  'project.stats': {'en': 'Project Statistics', 'zh': '專案統計'},
  'project.fileCount': {'en': 'Files', 'zh': '檔案數量'},
  'project.totalSize': {'en': 'Total Size', 'zh': '總大小'},
  'project.cloudFiles': {'en': 'Cloud', 'zh': '雲端'},
  'project.localFiles': {'en': 'Local', 'zh': '本地'},
  'project.noFiles': {'en': 'No files yet', 'zh': '尚無檔案'},
  'project.uploadHint': {'en': 'Tap + to upload files', 'zh': '點擊 + 上傳檔案'},
  
  // AI Features
  'ai.features': {'en': 'AI Features', 'zh': 'AI 功能'},
  'ai.chat': {'en': 'AI Chat', 'zh': 'AI 聊天'},
  'ai.notes': {'en': 'Key Notes', 'zh': '重點筆記'},
  'ai.flashcards': {'en': 'Flashcards', 'zh': '抽認卡'},
  'ai.questions': {'en': 'Practice Questions', 'zh': '練習問題'},
  
  // File Categories
  'file.all': {'en': 'All', 'zh': '全部'},
  'file.document': {'en': 'Documents', 'zh': '文件'},
  'file.image': {'en': 'Images', 'zh': '圖片'},
  'file.video': {'en': 'Videos', 'zh': '影片'},
  'file.audio': {'en': 'Audio', 'zh': '音訊'},
  'file.other': {'en': 'Other', 'zh': '其他'},
  
  // Dashboard additional
  'dashboard.sort': {'en': 'Sort', 'zh': '排序'},
  
  // Settings
  'settings.title': {'en': 'Settings', 'zh': '設定'},
  'settings.plan': {'en': 'Plan', 'zh': '方案'},
  'settings.usage': {'en': 'Usage', 'zh': '用量'},
  'settings.account': {'en': 'Account', 'zh': '帳號'},
  'settings.language': {'en': 'Language', 'zh': '語言'},
  'settings.aiSettings': {'en': 'AI Settings', 'zh': 'AI 設定'},
  'settings.dataSync': {'en': 'Data Sync', 'zh': '資料同步'},
  'settings.security': {'en': 'Security', 'zh': '安全性'},
  'settings.ghotePro': {'en': 'Ghote Pro', 'zh': 'Ghote Pro'},
  'settings.logout': {'en': 'Sign Out', 'zh': '登出'},
  'settings.changeDisplayName': {'en': 'Change display name', 'zh': '更改顯示名稱'},
  'settings.changeAvatar': {'en': 'Change avatar', 'zh': '更改頭像'},
  'settings.upgradePro': {'en': 'Upgrade to Ghote Pro', 'zh': '升級至 Ghote Pro'},
  'settings.geminiApiKey': {'en': 'Gemini API Key', 'zh': 'Gemini API 金鑰'},
  'settings.connected': {'en': 'Connected', 'zh': '已連線'},
  'settings.offlineMode': {'en': 'Offline Mode', 'zh': '離線模式'},
  'settings.autoSync': {'en': 'Auto sync to cloud', 'zh': '資料會自動同步到雲端'},
  'settings.pendingSync': {'en': 'Will sync when online', 'zh': '資料將在網路恢復時同步'},
  'settings.manualSync': {'en': 'Manual Sync', 'zh': '手動同步'},
  'settings.pendingCount': {'en': 'projects pending sync', 'zh': '個專案待同步'},
  
  // Dashboard additional (unique keys only)
  'dashboard.lastUpdated': {'en': 'Last Updated', 'zh': '最後更新'},
  'dashboard.createdAt': {'en': 'Created At', 'zh': '建立日期'},
  'dashboard.nameAZ': {'en': 'Name', 'zh': '名稱'},
  
  // Common UI (additional unique keys)
  'common.close': {'en': 'Close', 'zh': '關閉'},
  'common.apply': {'en': 'Apply', 'zh': '套用'},
  'common.upgrade': {'en': 'Upgrade', 'zh': '升級'},
  
  // Notes filter
  'notes.all': {'en': 'All', 'zh': '全部'},
  'notes.high': {'en': 'High importance', 'zh': '高重要性'},
  'notes.medium': {'en': 'Medium importance', 'zh': '中重要性'},
  'notes.low': {'en': 'Low importance', 'zh': '低重要性'},
  
  // Content Search
  'search.title': {'en': 'Content Search', 'zh': '內容搜尋'},
  'search.placeholder': {'en': 'Search flashcards, questions, notes...', 'zh': '搜尋抽認卡、題目、筆記...'},
  'search.noResults': {'en': 'No results found', 'zh': '找不到相關內容'},
  'search.difficulty': {'en': 'Difficulty', 'zh': '難度'},
  'search.tags': {'en': 'Tags', 'zh': '標籤'},
  'search.all': {'en': 'All', 'zh': '全部'},
  'search.easy': {'en': 'Easy', 'zh': '簡單'},
  'search.medium': {'en': 'Medium', 'zh': '中等'},
  'search.hard': {'en': 'Hard', 'zh': '困難'},
  'search.clearFilters': {'en': 'Clear filters', 'zh': '清除篩選'},
  'search.flashcards': {'en': 'Flashcards', 'zh': '抽認卡'},
  'search.questions': {'en': 'Questions', 'zh': '題目'},
  'search.notes': {'en': 'Notes', 'zh': '筆記'},
  'search.popularTags': {'en': 'Popular tags', 'zh': '熱門標籤'},
  'search.noFlashcards': {'en': 'No flashcards', 'zh': '沒有抽認卡'},
  'search.noQuestions': {'en': 'No questions', 'zh': '沒有題目'},
  'search.noNotes': {'en': 'No notes', 'zh': '沒有筆記'},
  'search.singleChoice': {'en': 'Single', 'zh': '單選'},
  'search.multipleChoice': {'en': 'Multiple', 'zh': '多選'},
  'search.openEnded': {'en': 'Open', 'zh': '問答'},
  
  // Sync
  'sync.connected': {'en': 'Connected', 'zh': '已連線'},
  'sync.offline': {'en': 'Offline Mode', 'zh': '離線模式'},
  'sync.autoSync': {'en': 'Data syncs automatically', 'zh': '資料會自動同步到雲端'},
  'sync.pendingSync': {'en': 'Will sync when online', 'zh': '資料將在網路恢復時同步'},
  'sync.manualSync': {'en': 'Manual Sync', 'zh': '手動同步'},

  // File operations
  'file.openFile': {'en': 'Open file', 'zh': '開啟檔案'},
  'file.fileInfo': {'en': 'File info', 'zh': '檔案資訊'},
  'file.deleteFile': {'en': 'Delete file', 'zh': '刪除檔案'},
  'file.fileName': {'en': 'File name', 'zh': '檔案名稱'},
  'file.fileType': {'en': 'File type', 'zh': '檔案類型'},
  'file.fileSize': {'en': 'File size', 'zh': '檔案大小'},
  'file.storageLocation': {'en': 'Storage', 'zh': '儲存位置'},
  'file.uploadTime': {'en': 'Upload time', 'zh': '上傳時間'},
  'file.localPath': {'en': 'Local path', 'zh': '本地路徑'},
  'file.downloadUrl': {'en': 'Download URL', 'zh': '下載網址'},
  'file.cloud': {'en': 'Cloud', 'zh': '雲端'},
  'file.local': {'en': 'Local', 'zh': '本地'},
  'file.noFiles': {'en': 'No files yet', 'zh': '尚無檔案'},
  'file.loadError': {'en': 'Load error', 'zh': '載入錯誤'},
  'file.processing': {'en': 'Processing', 'zh': '處理中'},
  'file.completed': {'en': 'Completed', 'zh': '已完成'},
  'file.failed': {'en': 'Failed', 'zh': '處理失敗'},
  'file.searchContent': {'en': 'Search content', 'zh': '搜尋內容'},
  'file.uploadFiles': {'en': 'Upload files', 'zh': '上傳檔案'},
  'file.openWith': {'en': 'Open with other app', 'zh': '用其他應用開啟'},
  'file.uploadHint': {'en': 'Tap + in top right to upload files', 'zh': '點擊右上角 + 開始上傳檔案'},
  'file.cannotOpen': {'en': 'Cannot open file', 'zh': '無法開啟檔案'},
  'file.cannotPreview': {'en': 'Preview not supported for this file type', 'zh': '此檔案類型不支援預覽'},
  'file.cannotShowImage': {'en': 'Cannot display image', 'zh': '無法顯示圖片'},
  'file.noApp': {'en': 'No app available to open this file type', 'zh': '沒有適合的應用程式可以開啟此類型的檔案'},
  'file.notExists': {'en': 'File does not exist', 'zh': '檔案不存在'},
  'file.permissionDenied': {'en': 'Permission denied', 'zh': '權限被拒絕'},
  
  // Project edit
  'project.editInfo': {'en': 'Edit project info', 'zh': '編輯專案資訊'},
  'project.name': {'en': 'Project name', 'zh': '專案名稱'},
  'project.nameHint': {'en': 'Enter project name', 'zh': '輸入專案名稱'},
  'project.descHint': {'en': 'Enter project description', 'zh': '輸入專案描述'},
  'project.colorTag': {'en': 'Color tag', 'zh': '顏色標籤'},
  'project.updated': {'en': 'Project info updated', 'zh': '專案資訊已更新'},
  'project.stats': {'en': 'Project Statistics', 'zh': '專案統計'},
  'project.fileCount': {'en': 'Files', 'zh': '檔案數量'},
  'project.totalSize': {'en': 'Total Size', 'zh': '總大小'},
  'project.cloudFiles': {'en': 'Cloud', 'zh': '雲端'},
  'project.localFiles': {'en': 'Local', 'zh': '本地'},
  
  // Time labels
  'time.noRecord': {'en': 'No record', 'zh': '無紀錄'},
  'time.justNow': {'en': 'Just now', 'zh': '剛剛'},
  
  // Network errors
  'error.networkIssue': {'en': 'Network connection issue', 'zh': '網路連線問題'},
  'error.cannotConnect': {'en': 'Cannot connect to server. Please check your connection.', 'zh': '無法連接到伺服器，請檢查您的網路連線。'},
  'error.pleaseLogin': {'en': 'Please login first', 'zh': '請先登入'},
  
  // Login
  'login.welcome': {'en': 'Welcome to Ghote', 'zh': '歡迎使用 Ghote'},
  'login.subtitle': {'en': 'AI-powered learning assistant', 'zh': 'AI 智能學習助手'},
  'login.google': {'en': 'Sign in with Google', 'zh': '使用 Google 登入'},
  'login.terms': {'en': 'By signing in, you agree to our Terms of Service', 'zh': '登入即表示您同意我們的服務條款'},
  
  // Chat
  'chat.title': {'en': 'AI Chat', 'zh': 'AI 聊天'},
  'chat.placeholder': {'en': 'Ask about your study materials...', 'zh': '針對學習資料提問...'},
  'chat.send': {'en': 'Send', 'zh': '發送'},
  
  // Flashcards
  'flashcards.title': {'en': 'Flashcards', 'zh': '抽認卡'},
  'flashcards.empty': {'en': 'No flashcards yet', 'zh': '還沒有抽認卡'},
  'flashcards.generate': {'en': 'Generate Flashcards', 'zh': '生成抽認卡'},
  'flashcards.generateConfirm': {'en': 'Generate flashcards', 'zh': '生成抽認卡'},
  'flashcards.generateDesc': {'en': 'AI will generate 10 flashcards from your files.\\n\\nThis may take a moment. Continue?', 'zh': '將使用 AI 根據您上傳的文件內容生成 10 張抽認卡。\\n\\n這可能需要一些時間，確定要繼續嗎？'},
  'flashcards.generating': {'en': 'Generating flashcards...', 'zh': 'AI 正在生成抽認卡...'},
  'flashcards.analyzeFiles': {'en': 'Analyzing files and generating cards', 'zh': '正在分析文件內容並生成學習卡片'},
  'flashcards.flip': {'en': 'Tap to flip', 'zh': '點擊翻轉'},
  'flashcards.flipToAnswer': {'en': 'Tap to see answer', 'zh': '點擊翻轉查看答案'},
  'flashcards.flipToQuestion': {'en': 'Tap to see question', 'zh': '點擊翻回問題'},
  'flashcards.mastered': {'en': 'Mastered', 'zh': '已掌握'},
  'flashcards.review': {'en': 'Need Review', 'zh': '需複習'},
  'flashcards.difficult': {'en': 'Difficult', 'zh': '困難'},
  'flashcards.unlearned': {'en': 'Not Started', 'zh': '未學習'},
  'flashcards.all': {'en': 'All', 'zh': '全部'},
  'flashcards.favorites': {'en': 'Favorites', 'zh': '收藏'},
  'flashcards.deleteAll': {'en': 'Delete all flashcards', 'zh': '刪除所有抽認卡'},
  'flashcards.deleteAllConfirm': {'en': 'Delete all flashcards?', 'zh': '刪除所有抽認卡'},
  'flashcards.deleteConfirmDesc': {'en': 'This action cannot be undone.', 'zh': '此操作無法復原。'},
  'flashcards.noMastered': {'en': 'No mastered cards yet', 'zh': '還沒有已掌握的卡片'},
  'flashcards.noReview': {'en': 'No cards to review', 'zh': '沒有需要複習的卡片'},
  'flashcards.noDifficult': {'en': 'No difficult cards', 'zh': '沒有困難的卡片'},
  'flashcards.allLearned': {'en': 'All cards learned!', 'zh': '所有卡片都已學習過'},
  'flashcards.noFavorites': {'en': 'No favorites yet', 'zh': '還沒有收藏的抽認卡'},
  'flashcards.showAll': {'en': 'Show all', 'zh': '顯示全部'},
  'flashcards.question': {'en': 'Question', 'zh': '問題'},
  'flashcards.answer': {'en': 'Answer', 'zh': '答案'},
  'flashcards.addedFavorite': {'en': 'Added to favorites', 'zh': '已加入收藏'},
  'flashcards.removedFavorite': {'en': 'Removed from favorites', 'zh': '已取消收藏'},
  'flashcards.markedAs': {'en': 'Marked as', 'zh': '已標記為'},
  'flashcards.language': {'en': 'Language:', 'zh': '生成語言：'},
  'flashcards.startGenerate': {'en': 'Start generating', 'zh': '開始生成'},
  'flashcards.cardCount': {'en': 'Card', 'zh': '張'},
  
  // Notes
  'notes.title': {'en': 'Key Notes', 'zh': '重點筆記'},
  'notes.empty': {'en': 'No notes yet', 'zh': '尚無筆記'},
  'notes.generate': {'en': 'Generate notes from your files', 'zh': '從檔案生成筆記'},
  
  // Questions
  'questions.title': {'en': 'Practice Questions', 'zh': '練習題目'},
  'questions.empty': {'en': 'No questions yet', 'zh': '尚無題目'},
  'questions.start': {'en': 'Start Quiz', 'zh': '開始測驗'},
  'questions.single': {'en': 'Single Choice', 'zh': '單選題'},
  'questions.multiple': {'en': 'Multiple Choice', 'zh': '多選題'},
  'questions.openEnded': {'en': 'Open-ended', 'zh': '問答題'},
  
  // Quiz
  'quiz.title': {'en': 'Quiz', 'zh': '測驗'},
  'quiz.submit': {'en': 'Submit', 'zh': '提交'},
  'quiz.next': {'en': 'Next', 'zh': '下一題'},
  'quiz.finish': {'en': 'Finish', 'zh': '完成'},
  'quiz.correct': {'en': 'Correct!', 'zh': '正確！'},
  'quiz.incorrect': {'en': 'Incorrect', 'zh': '錯誤'},
  
  // Learning Progress
  'progress.title': {'en': 'Learning Progress', 'zh': '學習進度'},
  'progress.flashcardsProgress': {'en': 'Flashcards', 'zh': '抽認卡進度'},
  'progress.quizAccuracy': {'en': 'Quiz Accuracy', 'zh': '測驗正確率'},
  'progress.mastered': {'en': 'mastered', 'zh': '已掌握'},
  'progress.questions': {'en': 'questions', 'zh': '題'},
  'progress.lastStudy': {'en': 'Last study', 'zh': '最後學習'},
  'progress.startLearning': {'en': 'Start learning with flashcards or quizzes', 'zh': '使用抽認卡或測驗開始學習，追蹤您的進度'},
  
  // Errors & Messages
  'error.network': {'en': 'Network error. Please check your connection.', 'zh': '網路錯誤，請檢查連線。'},
  'error.upload': {'en': 'Upload failed', 'zh': '上傳失敗'},
  'error.fileTooLarge': {'en': 'File size exceeds 10MB limit', 'zh': '檔案大小超過 10MB 上限'},
  'error.projectLimit': {'en': 'Project limit reached. Upgrade to Pro for unlimited projects.', 'zh': '專案數量已達上限。升級 Pro 享受無限專案。'},
  'error.fileLimit': {'en': 'File limit reached. Upgrade to Pro for unlimited files.', 'zh': '檔案數量已達上限。升級 Pro 享受無限檔案。'},
  
  // Toasts
  'toast.saved': {'en': 'Saved successfully', 'zh': '儲存成功'},
  'toast.deleted': {'en': 'Deleted successfully', 'zh': '刪除成功'},
  'toast.uploaded': {'en': 'Uploaded successfully', 'zh': '上傳成功'},
  'toast.copied': {'en': 'Copied to clipboard', 'zh': '已複製到剪貼簿'},
};
