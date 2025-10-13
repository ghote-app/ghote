import 'package:flutter/foundation.dart';
// Conditional storage: web uses localStorage; other platforms use stubs
import 'i18n_storage_stub.dart' if (dart.library.html) 'i18n_storage_web.dart' as storage;

enum AppLocale { en, zh }

class LocaleController extends ChangeNotifier {
  AppLocale _locale = _detectInitialLocale();
  AppLocale get locale => _locale;

  static AppLocale _detectInitialLocale() {
    final saved = storage.loadSaved();
    if (saved == 'en') return AppLocale.en;
    if (saved == 'zh') return AppLocale.zh;
    final lang = (storage.browserLang() ?? '').toLowerCase();
    return lang.startsWith('zh') ? AppLocale.zh : AppLocale.en;
  }

  void setLocale(AppLocale locale) {
    _locale = locale;
    storage.save(locale == AppLocale.en ? 'en' : 'zh');
    notifyListeners();
  }
}

final LocaleController localeController = LocaleController();

String t(String key) {
  final l = localeController.locale;
  final map = _strings[key];
  if (map == null) return key;
  return l == AppLocale.en ? (map['en'] ?? key) : (map['zh'] ?? key);
}

final Map<String, Map<String, String>> _strings = {
  // App / Nav
  'app.title': {'en': 'Ghote', 'zh': 'Ghote'},
  'nav.terms': {'en': 'Terms', 'zh': '服務條款'},
  'nav.privacy': {'en': 'Privacy', 'zh': '隱私政策'},
  'nav.download': {'en': 'Get the App', 'zh': '下載應用程式'},

  // Hero
  'hero.title': {
    'en': 'Welcome to Ghote',
    'zh': '歡迎來到 Ghote',
  },
  'hero.subtitle': {
    'en': 'AI learning assistant to accelerate your study',
    'zh': '智能學習輔助 App，讓 AI 為您的學習加速',
  },

  // Features
  'features.title': {
    'en': 'Why Ghote?',
    'zh': '為什麼選擇 Ghote？',
  },
  'feature.ai.title': {
    'en': 'AI Knowledge Extraction',
    'zh': 'AI 智能分析',
  },
  'feature.ai.desc': {
    'en': 'Extract key points and generate notes, MCQs, Q&A, and flashcards.',
    'zh': '自動從學習資料中提取核心知識，生成重點筆記、選擇題、問答題及抽認卡',
  },
  'feature.project.title': {
    'en': 'Project Management',
    'zh': '專案管理',
  },
  'feature.project.desc': {
    'en': 'Organize subjects by projects to track progress quickly.',
    'zh': '以專案為單位管理不同科目或主題的學習資料，快速掌握學習狀態',
  },
  'feature.search.title': {
    'en': 'Smart Search',
    'zh': '智能搜尋',
  },
  'feature.search.desc': {
    'en': 'Built-in filters (All/Active/Completed/Archived) to find content fast.',
    'zh': '內建搜尋與篩選功能 (All/Active/Completed/Archived)，快速找到所需內容',
  },

  // Footer / Common
  'footer.copyright': {
    'en': '© 2025 Ghote. All rights reserved.',
    'zh': '© 2025 Ghote. 版權所有。',
  },
  'common.backHome': {'en': 'Back to Home', 'zh': '返回首頁'},

  // Legal pages
  'tos.appbar': {'en': 'Terms of Service', 'zh': '服務條款'},
  'tos.title': {'en': 'Ghote Terms of Service', 'zh': 'Ghote 服務條款'},
  'privacy.appbar': {'en': 'Privacy Policy', 'zh': '隱私政策'},
  'privacy.title': {'en': 'Ghote Privacy Policy', 'zh': 'Ghote 隱私政策'},
};


