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
            // '最後更新：2025年10月10日'
            Text(
              t('tos.updated'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              // '1. 接受條款'
              t('tos.section1.title'),
              t('tos.section1.content'),
            ),
            _buildSection(
              // '2. 服務描述'
              t('tos.section2.title'),
              t('tos.section2.content'),
            ),
            _buildSection(
              // '3. 用戶責任'
              t('tos.section3.title'),
              t('tos.section3.content'),
            ),
            _buildSection(
              // '4. 隱私保護'
              t('tos.section4.title'),
              t('tos.section4.content'),
            ),
            _buildSection(
              // '5. 智慧財產權'
              t('tos.section5.title'),
              t('tos.section5.content'),
            ),
            _buildSection(
              // '6. 服務變更'
              t('tos.section6.title'),
              t('tos.section6.content'),
            ),
            _buildSection(
              // '7. 免責聲明'
              t('tos.section7.title'),
              t('tos.section7.content'),
            ),
            _buildSection(
              // '8. 責任限制'
              t('tos.section8.title'),
              t('tos.section8.content'),
            ),
            _buildSection(
              // '9. 爭議解決'
              t('tos.section9.title'),
              t('tos.section9.content'),
            ),
            _buildSection(
              // '10. 條款修改'
              t('tos.section10.title'),
              t('tos.section10.content'),
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
                  // '聯絡我們'
                  Text(
                    t('tos.contact.title'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('tos.contact.intro'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('tos.email'),
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
