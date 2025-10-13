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
  'privacy.updated': {
    'en': 'Last Updated: October 10, 2025',
    'zh': '最後更新：2025年10月10日',
  },
  'privacy.section1.title': {'en': '1. Information We Collect', 'zh': '1. 資訊收集'},
  'privacy.section1.content': {
    'en': 'We collect the following types of information:\n\n• Account Information: Name, email address\n• Learning Materials: PDF/DOCX documents you upload, study notes\n• Usage Data: App usage, learning progress, AI-generated content\n• Device Information: Device type, operating system version\n• Location Information: Collected only with your consent',
    'zh': '我們收集以下類型的資訊：\n\n• 帳戶資訊：姓名、電子郵件地址\n• 學習資料：您上傳的 PDF/DOCX 文件、學習筆記\n• 使用資料：應用程式使用情況、學習進度、AI 生成的內容\n• 裝置資訊：裝置類型、作業系統版本\n• 位置資訊：僅在您授權時收集',
  },
  'privacy.section2.title': {'en': '2. How We Use Your Information', 'zh': '2. 資訊使用'},
  'privacy.section2.content': {
    'en': 'We use the collected information to:\n\n• Provide and improve our AI study assistance services\n• Automatically analyze your learning materials and generate study resources\n• Personalize your learning experience and progress tracking\n• Communicate important updates and study recommendations\n• Ensure service security and quality',
    'zh': '我們使用收集的資訊來：\n\n• 提供和改善我們的 AI 學習輔助服務\n• 自動分析您的學習資料並生成學習材料\n• 個性化您的學習體驗和進度追蹤\n• 與您溝通重要更新和學習建議\n• 確保服務安全和品質',
  },
  'privacy.section3.title': {'en': '3. Information Sharing', 'zh': '3. 資訊分享'},
  'privacy.section3.content': {
    'en': 'We do not sell, trade, or transfer your personal information to third parties, unless:\n\n• We have your explicit consent\n• Required by law or court order\n• Necessary to protect our rights and property',
    'zh': '我們不會出售、交易或轉讓您的個人資訊給第三方，除非：\n\n• 獲得您的明確同意\n• 法律要求或法院命令\n• 保護我們的權利和財產',
  },
  'privacy.section4.title': {'en': '4. Data Security', 'zh': '4. 資料安全'},
  'privacy.section4.content': {
    'en': 'We employ industry-standard security measures to protect your information:\n\n• Encrypted transmission and storage\n• Regular security audits\n• Restricted employee access\n• Monitoring for anomalous activities',
    'zh': '我們採用業界標準的安全措施來保護您的資訊：\n\n• 加密傳輸和儲存\n• 定期安全審計\n• 限制員工存取權限\n• 監控異常活動',
  },
  'privacy.section5.title': {'en': '5. Cookies and Tracking', 'zh': '5. Cookie 和追蹤'},
  'privacy.section5.content': {
    'en': 'We use cookies and similar technologies to:\n\n• Remember your preferences\n• Analyze website usage\n• Improve user experience\n• Deliver personalized content',
    'zh': '我們使用 Cookie 和類似技術來：\n\n• 記住您的偏好設定\n• 分析網站使用情況\n• 改善用戶體驗\n• 提供個人化內容',
  },
  'privacy.section6.title': {'en': '6. Third-Party Services', 'zh': '6. 第三方服務'},
  'privacy.section6.content': {
    'en': 'We may use the following third-party services:\n\n• Google Analytics: Usage analytics\n• Firebase: Backend services and authentication\n• Google Gemini API: AI content generation\n• Cloudflare R2: Document storage (PDF/DOCX)\n• Neon PostgreSQL: Database services\n• Render: Backend API deployment',
    'zh': '我們可能使用以下第三方服務：\n\n• Google Analytics：分析使用情況\n• Firebase：後端服務和認證\n• Google Gemini API：AI 內容生成\n• Cloudflare R2：文件儲存 (PDF/DOCX)\n• Neon PostgreSQL：資料庫服務\n• Render：後端 API 部署',
  },
  'privacy.section7.title': {'en': "7. Children's Privacy", 'zh': '7. 兒童隱私'},
  'privacy.section7.content': {
    'en': 'We do not knowingly collect personal information from children under the age of 13. If we discover such collection, we will promptly delete the information.',
    'zh': '我們不會故意收集 13 歲以下兒童的個人資訊。如果我們發現收集了此類資訊，將立即刪除。',
  },
  'privacy.section8.title': {'en': '8. Your Rights', 'zh': '8. 您的權利'},
  'privacy.section8.content': {
    'en': 'You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Delete your account and data\n• Restrict processing\n• Data portability',
    'zh': '您有權：\n\n• 存取您的個人資訊\n• 更正不準確的資訊\n• 刪除您的帳戶和資料\n• 限制資料處理\n• 資料可攜性',
  },
  'privacy.section9.title': {'en': '9. International Transfers', 'zh': '9. 國際傳輸'},
  'privacy.section9.content': {
    'en': 'Your information may be transferred to servers located outside your country or region. We implement appropriate safeguards to protect your data.',
    'zh': '您的資訊可能被傳輸到您所在國家/地區以外的伺服器。我們確保適當的保護措施。',
  },
  'privacy.section10.title': {'en': '10. Policy Updates', 'zh': '10. 政策更新'},
  'privacy.section10.content': {
    'en': 'We may update this Privacy Policy from time to time. Material changes will be communicated via the app or by email.',
    'zh': '我們可能會更新本隱私政策。重大變更將透過應用程式或電子郵件通知您。',
  },
  'privacy.cta.title': {'en': 'Your Privacy Matters', 'zh': '您的隱私很重要'},
  'privacy.cta.content': {
    'en': 'We are committed to protecting your privacy and handling your data transparently. If you have any questions or concerns, please contact us anytime.',
    'zh': '我們承諾保護您的隱私並透明地處理您的資料。如果您有任何疑問或疑慮，請隨時聯絡我們。',
  },
  'privacy.email': {
    'en': 'Email: ghote.app@gmail.com',
    'zh': '電子郵件：ghote.app@gmail.com',
  },

  // Terms of Service details
  'tos.updated': {
    'en': 'Last Updated: October 10, 2025',
    'zh': '最後更新：2025年10月10日',
  },
  'tos.section1.title': {'en': '1. Acceptance of Terms', 'zh': '1. 接受條款'},
  'tos.section1.content': {
    'en': 'By using the Ghote application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
    'zh': '通過使用 Ghote 應用程式，您同意受本服務條款的約束。如果您不同意這些條款，請不要使用我們的服務。',
  },
  'tos.section2.title': {'en': '2. Description of Service', 'zh': '2. 服務描述'},
  'tos.section2.content': {
    'en': 'Ghote is an intelligent study-assistance app focused on learning and knowledge organization. Leveraging AI, it automatically extracts core knowledge from your study materials and presents content in multiple formats, including key notes, multiple-choice questions, Q&A, and flashcards. Users can create Projects to manage different subjects or topics, and AI will analyze and generate various study materials.',
    'zh': 'Ghote 是一個專注學習與知識整理的智能學習輔助 App，透過 AI 技術自動從學習資料中提取核心知識，並以多種形式呈現學習內容，包括重點筆記、選擇題、問答題及抽認卡。用戶可以建立 Project 管理不同科目或主題的學習資料，AI 會自動分析並生成各種學習材料。',
  },
  'tos.section3.title': {'en': '3. User Responsibilities', 'zh': '3. 用戶責任'},
  'tos.section3.content': {
    'en': 'You agree to:\n• Provide accurate registration information\n• Maintain the security of your account\n• Comply with all applicable laws and regulations\n• Refrain from activities that may harm the service',
    'zh': '您同意：\n• 提供準確的註冊資訊\n• 維護帳戶安全\n• 遵守所有適用的法律法規\n• 不進行任何可能損害服務的行為',
  },
  'tos.section4.title': {'en': '4. Privacy Protection', 'zh': '4. 隱私保護'},
  'tos.section4.content': {
    'en': 'We value your privacy. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.',
    'zh': '我們重視您的隱私。請查看我們的隱私政策以了解我們如何收集、使用和保護您的個人資訊。',
  },
  'tos.section5.title': {'en': '5. Intellectual Property', 'zh': '5. 智慧財產權'},
  'tos.section5.content': {
    'en': 'Ghote and its content are protected by intellectual property laws. You may not copy, distribute, or modify our content without authorization.',
    'zh': 'Ghote 及其內容受智慧財產權法保護。未經授權，您不得複製、分發或修改我們的內容。',
  },
  'tos.section6.title': {'en': '6. Changes to the Service', 'zh': '6. 服務變更'},
  'tos.section6.content': {
    'en': 'We reserve the right to modify or discontinue the service at any time. For material changes, users will be notified in advance.',
    'zh': '我們保留隨時修改或終止服務的權利。重大變更將提前通知用戶。',
  },
  'tos.section7.title': {'en': '7. Disclaimer', 'zh': '7. 免責聲明'},
  'tos.section7.content': {
    'en': 'The service is provided “as is.” We do not warrant the continuity, accuracy, or error-free nature of the service.',
    'zh': '服務按「現狀」提供。我們不保證服務的連續性、準確性或無錯誤。',
  },
  'tos.section8.title': {'en': '8. Limitation of Liability', 'zh': '8. 責任限制'},
  'tos.section8.content': {
    'en': 'To the maximum extent permitted by law, Ghote shall not be liable for any indirect, incidental, or consequential damages.',
    'zh': '在法律允許的最大範圍內，Ghote 不對任何間接、偶然或後果性損害承擔責任。',
  },
  'tos.section9.title': {'en': '9. Dispute Resolution', 'zh': '9. 爭議解決'},
  'tos.section9.content': {
    'en': 'Any disputes shall first be resolved through friendly negotiations. If unresolved, the dispute shall be submitted to a court of competent jurisdiction.',
    'zh': '任何爭議將通過友好協商解決。如無法協商，將提交至有管轄權的法院。',
  },
  'tos.section10.title': {'en': '10. Changes to These Terms', 'zh': '10. 條款修改'},
  'tos.section10.content': {
    'en': 'We reserve the right to modify these Terms at any time. Updated terms will be published on the website.',
    'zh': '我們保留隨時修改本條款的權利。修改後的條款將在網站上公佈。',
  },
  'tos.contact.title': {'en': 'Contact Us', 'zh': '聯絡我們'},
  'tos.contact.intro': {
    'en': 'If you have any questions about these Terms of Service, please contact us via:',
    'zh': '如果您對本服務條款有任何疑問，請透過以下方式聯絡我們：',
  },
  'tos.email': {
    'en': 'Email: ghote.app@gmail.com',
    'zh': '電子郵件：ghote.app@gmail.com',
  },
};


