import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'i18n.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          t('privacy.appbar'),
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
              t('privacy.title'),
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
              '1. 資訊收集',
              '我們收集以下類型的資訊：\n\n'
              '• 帳戶資訊：姓名、電子郵件地址\n'
              '• 學習資料：您上傳的 PDF/DOCX 文件、學習筆記\n'
              '• 使用資料：應用程式使用情況、學習進度、AI 生成的內容\n'
              '• 裝置資訊：裝置類型、作業系統版本\n'
              '• 位置資訊：僅在您授權時收集',
            ),
            _buildSection(
              '2. 資訊使用',
              '我們使用收集的資訊來：\n\n'
              '• 提供和改善我們的 AI 學習輔助服務\n'
              '• 自動分析您的學習資料並生成學習材料\n'
              '• 個性化您的學習體驗和進度追蹤\n'
              '• 與您溝通重要更新和學習建議\n'
              '• 確保服務安全和品質',
            ),
            _buildSection(
              '3. 資訊分享',
              '我們不會出售、交易或轉讓您的個人資訊給第三方，除非：\n\n'
              '• 獲得您的明確同意\n'
              '• 法律要求或法院命令\n'
              '• 保護我們的權利和財產',
            ),
            _buildSection(
              '4. 資料安全',
              '我們採用業界標準的安全措施來保護您的資訊：\n\n'
              '• 加密傳輸和儲存\n'
              '• 定期安全審計\n'
              '• 限制員工存取權限\n'
              '• 監控異常活動',
            ),
            _buildSection(
              '5. Cookie 和追蹤',
              '我們使用 Cookie 和類似技術來：\n\n'
              '• 記住您的偏好設定\n'
              '• 分析網站使用情況\n'
              '• 改善用戶體驗\n'
              '• 提供個人化內容',
            ),
            _buildSection(
              '6. 第三方服務',
              '我們可能使用以下第三方服務：\n\n'
              '• Google Analytics：分析使用情況\n'
              '• Firebase：後端服務和認證\n'
              '• Google Gemini API：AI 內容生成\n'
              '• Cloudflare R2：文件儲存 (PDF/DOCX)\n'
              '• Neon PostgreSQL：資料庫服務\n'
              '• Render：後端 API 部署',
            ),
            _buildSection(
              '7. 兒童隱私',
              '我們不會故意收集 13 歲以下兒童的個人資訊。如果我們發現收集了此類資訊，將立即刪除。',
            ),
            _buildSection(
              '8. 您的權利',
              '您有權：\n\n'
              '• 存取您的個人資訊\n'
              '• 更正不準確的資訊\n'
              '• 刪除您的帳戶和資料\n'
              '• 限制資料處理\n'
              '• 資料可攜性',
            ),
            _buildSection(
              '9. 國際傳輸',
              '您的資訊可能被傳輸到您所在國家/地區以外的伺服器。我們確保適當的保護措施。',
            ),
            _buildSection(
              '10. 政策更新',
              '我們可能會更新本隱私政策。重大變更將透過應用程式或電子郵件通知您。',
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '您的隱私很重要',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '我們承諾保護您的隱私並透明地處理您的資料。如果您有任何疑問或疑慮，請隨時聯絡我們。',
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
                  backgroundColor: Colors.green.shade600,
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
