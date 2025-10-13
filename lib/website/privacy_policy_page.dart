import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'i18n.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
            // '最後更新：2025年10月10日'
            Text(
              t('privacy.updated'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              // '1. 資訊收集'
              t('privacy.section1.title'),
              // 上方為舊字串
              t('privacy.section1.content'),
            ),
            _buildSection(
              // '2. 資訊使用'
              t('privacy.section2.title'),
              t('privacy.section2.content'),
            ),
            _buildSection(
              // '3. 資訊分享'
              t('privacy.section3.title'),
              t('privacy.section3.content'),
            ),
            _buildSection(
              // '4. 資料安全'
              t('privacy.section4.title'),
              t('privacy.section4.content'),
            ),
            _buildSection(
              // '5. Cookie 和追蹤'
              t('privacy.section5.title'),
              t('privacy.section5.content'),
            ),
            _buildSection(
              // '6. 第三方服務'
              t('privacy.section6.title'),
              t('privacy.section6.content'),
            ),
            _buildSection(
              // '7. 兒童隱私'
              t('privacy.section7.title'),
              t('privacy.section7.content'),
            ),
            _buildSection(
              // '8. 您的權利'
              t('privacy.section8.title'),
              t('privacy.section8.content'),
            ),
            _buildSection(
              // '9. 國際傳輸'
              t('privacy.section9.title'),
              t('privacy.section9.content'),
            ),
            _buildSection(
              // '10. 政策更新'
              t('privacy.section10.title'),
              t('privacy.section10.content'),
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
                  // '您的隱私很重要'
                  Text(
                    t('privacy.cta.title'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('privacy.cta.content'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('privacy.email'),
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
