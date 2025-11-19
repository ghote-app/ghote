import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../i18n.dart';
import 'tech_icons.dart';

class TechStackSection extends StatelessWidget {
  const TechStackSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 768 ? 16 : 24,
            vertical: MediaQuery.of(context).size.width < 768 ? 60 : 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  localeController.locale == AppLocale.en
                      ? 'Built with'
                      : '技術棧',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildTechGrid(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    // First row (3 items) - larger icons
    final firstRow = [
      {
        'name': 'Flutter',
        'color': Colors.white,
        'url': 'https://flutter.dev/',
        'size': isMobile ? 80.0 : (isTablet ? 100.0 : 120.0),
      },
      {
        'name': 'Firebase',
        'color': Colors.white,
        'url': 'https://firebase.google.com/',
        'size': isMobile ? 100.0 : (isTablet ? 130.0 : 150.0),
      },
      {
        'name': 'Google Gemini',
        'color': Colors.white,
        'url': 'https://ai.google.dev/',
        'size': isMobile ? 70.0 : (isTablet ? 85.0 : 100.0),
      },
    ];

    // Second row (7 items) - smaller icons
    final secondRow = [
      {
        'name': 'Dart',
        'color': Colors.white,
        'url': 'https://dart.dev/',
        'size': isMobile ? 70.0 : (isTablet ? 85.0 : 100.0),
      },
      {
        'name': 'Cloud Firestore',
        'color': Colors.white,
        'url': 'https://firebase.google.com/products/firestore',
        'size': isMobile ? 60.0 : (isTablet ? 75.0 : 90.0),
      },
      {
        'name': 'Firebase Auth',
        'color': Colors.white,
        'url': 'https://firebase.google.com/products/auth',
        'size': isMobile ? 60.0 : (isTablet ? 75.0 : 90.0),
      },
      {
        'name': 'Firebase Storage',
        'color': Colors.white,
        'url': 'https://firebase.google.com/products/storage',
        'size': isMobile ? 60.0 : (isTablet ? 75.0 : 90.0),
      },
      {
        'name': 'Go Router',
        'color': Colors.white,
        'url': 'https://pub.dev/packages/go_router',
        'size': isMobile ? 60.0 : (isTablet ? 75.0 : 90.0),
      },
      {
        'name': 'Google Fonts',
        'color': Colors.white,
        'url': 'https://fonts.google.com/',
        'size': isMobile ? 60.0 : (isTablet ? 75.0 : 90.0),
      },
      {
        'name': 'Syncfusion PDF',
        'color': Colors.white,
        'url': 'https://pub.dev/packages/syncfusion_flutter_pdf',
        'size': isMobile ? 60.0 : (isTablet ? 75.0 : 90.0),
      },
    ];

    if (isMobile) {
      // Mobile: 2 columns grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.0,
        ),
        itemCount: firstRow.length + secondRow.length,
        itemBuilder: (context, index) {
          final allTech = [...firstRow, ...secondRow];
          final tech = allTech[index];
          return _buildTechItem(
            context,
            tech['name'] as String,
            tech['color'] as Color,
            tech['url'] as String,
            tech['size'] as double,
            index,
          );
        },
      );
    }

    if (isTablet) {
      // Tablet: Adjust layout
      return Column(
        children: [
            // First row - 3 columns
            Row(
              children: List.generate(
                firstRow.length,
                (index) {
                  final tech = firstRow[index];
                  return Expanded(
                    child: Container(
                      height: screenHeight * 0.2,
                      decoration: BoxDecoration(
                        border: Border(
                          right: index < firstRow.length - 1
                              ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                              : BorderSide.none,
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: _buildTechItem(
                        context,
                        tech['name'] as String,
                        tech['color'] as Color,
                        tech['url'] as String,
                        tech['size'] as double,
                        index,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Second row - 7 columns (may wrap)
            Wrap(
              children: List.generate(
                secondRow.length,
                (index) {
                  final tech = secondRow[index];
                  return SizedBox(
                    width: screenWidth / 7,
                    height: screenHeight * 0.15,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: _buildTechItem(
                        context,
                        tech['name'] as String,
                        tech['color'] as Color,
                        tech['url'] as String,
                        tech['size'] as double,
                        firstRow.length + index,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
    }

    // Desktop: First row (3 columns), Second row (7 columns)
    return Column(
      children: [
          // First row - 3 columns
          Row(
            children: List.generate(
              firstRow.length,
              (index) {
                final tech = firstRow[index];
                return Expanded(
                  child: Container(
                    height: screenHeight * 0.25.clamp(200.0, 400.0),
                    decoration: BoxDecoration(
                      border: Border(
                        right: index < firstRow.length - 1
                            ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                            : BorderSide.none,
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: _buildTechItem(
                      context,
                      tech['name'] as String,
                      tech['color'] as Color,
                      tech['url'] as String,
                      tech['size'] as double,
                      index,
                    ),
                  ),
                );
              },
            ),
        ),
        // Second row - 7 columns
        Row(
            children: List.generate(
              secondRow.length,
              (index) {
                final tech = secondRow[index];
                return Expanded(
                  child: Container(
                    height: screenHeight * 0.2.clamp(150.0, 300.0),
                    decoration: BoxDecoration(
                      border: Border(
                        right: index < secondRow.length - 1
                            ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                            : BorderSide.none,
                      ),
                    ),
                    child: _buildTechItem(
                      context,
                      tech['name'] as String,
                      tech['color'] as Color,
                      tech['url'] as String,
                      tech['size'] as double,
                      firstRow.length + index,
                    ),
                  ),
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildTechItem(
    BuildContext context,
    String name,
    Color color,
    String url,
    double size,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // Ensure icon is always visible - start from 0.5 opacity minimum
        final opacity = (value * 0.5 + 0.5).clamp(0.5, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('tech-item-$index'),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: TechIcon(
            name: name,
            url: url,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }
}

