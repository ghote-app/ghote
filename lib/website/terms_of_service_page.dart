import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'i18n.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
            title: Text(
              t('tos.appbar'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              t('tos.title'),
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '最後更新：2025年10月10日',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              '1. 接受條款',
              '通過使用 Ghote 應用程式，您同意受本服務條款的約束。如果您不同意這些條款，請不要使用我們的服務。',
            ),
            _buildSection(
              '2. 服務描述',
              'Ghote 是一個專注學習與知識整理的智能學習輔助 App，透過 AI 技術自動從學習資料中提取核心知識，並以多種形式呈現學習內容，包括重點筆記、選擇題、問答題及抽認卡。用戶可以建立 Project 管理不同科目或主題的學習資料，AI 會自動分析並生成各種學習材料。',
            ),
            _buildSection(
              '3. 用戶責任',
              '您同意：\n'
              '• 提供準確的註冊資訊\n'
              '• 維護帳戶安全\n'
              '• 遵守所有適用的法律法規\n'
              '• 不進行任何可能損害服務的行為',
            ),
            _buildSection(
              '4. 隱私保護',
              '我們重視您的隱私。請查看我們的隱私政策以了解我們如何收集、使用和保護您的個人資訊。',
            ),
            _buildSection(
              '5. 智慧財產權',
              'Ghote 及其內容受智慧財產權法保護。未經授權，您不得複製、分發或修改我們的內容。',
            ),
            _buildSection(
              '6. 服務變更',
              '我們保留隨時修改或終止服務的權利。重大變更將提前通知用戶。',
            ),
            _buildSection(
              '7. 免責聲明',
              '服務按「現狀」提供。我們不保證服務的連續性、準確性或無錯誤。',
            ),
            _buildSection(
              '8. 責任限制',
              '在法律允許的最大範圍內，Ghote 不對任何間接、偶然或後果性損害承擔責任。',
            ),
            _buildSection(
              '9. 爭議解決',
              '任何爭議將通過友好協商解決。如無法協商，將提交至有管轄權的法院。',
            ),
            _buildSection(
              '10. 條款修改',
              '我們保留隨時修改本條款的權利。修改後的條款將在網站上公佈。',
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '聯絡我們',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '如果您對本服務條款有任何疑問，請透過以下方式聯絡我們：',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '電子郵件：ghote.app@gmail.com',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  t('common.backHome'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
