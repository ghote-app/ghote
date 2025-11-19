import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'i18n.dart';
import 'widgets/dot_grid_background.dart';
import 'widgets/scroll_text_animation.dart';
import 'widgets/tech_stack_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background layer
              const Positioned.fill(
                child: DotGridBackground(),
              ),
              // Content layer
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildHeroSection(context),
                    _buildTechStackSection(context),
                    _buildFeaturesSection(context),
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        final currentLocale = localeController.locale;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: PopupMenuButton<AppLocale>(
            tooltip: currentLocale == AppLocale.en ? 'Language' : '語言',
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentLocale == AppLocale.en ? 'EN' : '中文',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
            onSelected: (v) => localeController.setLocale(v),
            itemBuilder: (_) => [
              PopupMenuItem<AppLocale>(
                value: AppLocale.en,
                child: Row(
                  children: [
                    Icon(
                      currentLocale == AppLocale.en
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: currentLocale == AppLocale.en
                          ? Colors.blue
                          : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'English',
                      style: GoogleFonts.inter(
                        color: currentLocale == AppLocale.en
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: currentLocale == AppLocale.en
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppLocale>(
                value: AppLocale.zh,
                child: Row(
                  children: [
                    Icon(
                      currentLocale == AppLocale.zh
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: currentLocale == AppLocale.zh
                          ? Colors.blue
                          : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '中文',
                      style: GoogleFonts.inter(
                        color: currentLocale == AppLocale.zh
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: currentLocale == AppLocale.zh
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/AppIcon/Ghote_icon_black_background.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 12),
              Text(
                t('app.title'),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildLanguageSelector(context),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.go('/terms'),
                child: Text(
                  t('nav.terms'),
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => context.go('/privacy'),
                child: Text(
                  t('nav.privacy'),
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: double.infinity,
      height: screenHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/AppIcon/Ghote_icon_black_background.png',
            width: 140,
            height: 140,
          ),
          const SizedBox(height: 48),
          Text(
            t('hero.title'),
            style: GoogleFonts.inter(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            t('hero.subtitle'),
            style: GoogleFonts.inter(
              fontSize: 22,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to app store
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  child: Text(
                    t('nav.download'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    
    final textHeight = isMobile 
        ? screenHeight * 0.4 
        : (screenHeight * 0.5).clamp(300.0, 600.0);
    
    final fontSize = isMobile 
        ? 60.0 
        : (screenWidth < 1024 ? 120.0 : (screenWidth < 1920 ? 200.0 : 250.0));
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 40 : 60,
      ),
      child: Column(
        children: [
          SizedBox(
            height: textHeight,
            child: ScrollTextAnimation(
              scrollController: _scrollController,
              text: localeController.locale == AppLocale.en
                  ? 'TECH STACK'
                  : '技術棧',
              fontSize: fontSize,
            ),
          ),
          const SizedBox(height: 40),
          const TechStackSection(),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': t('feature.ai.title'),
        'description': t('feature.ai.desc'),
      },
      {
        'icon': Icons.folder_special,
        'title': t('feature.project.title'),
        'description': t('feature.project.desc'),
      },
      {
        'icon': Icons.search,
        'title': t('feature.search.title'),
        'description': t('feature.search.desc'),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Column(
        children: [
          Text(
            t('features.title'),
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          ...features.map((feature) => Container(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.3),
                        Colors.purple.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Colors.blue.shade300,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        feature['description'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/AppIcon/Ghote_icon_black_background.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ghote',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/terms'),
                    child: Text(
                      t('nav.terms'),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => context.go('/privacy'),
                    child: Text(
                      t('nav.privacy'),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            t('footer.copyright'),
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
