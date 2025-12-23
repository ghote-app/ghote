import 'package:flutter/material.dart';

import '../../../../utils/app_locale.dart';

/// Callback for AI action button tap
typedef AIActionCallback = void Function();

/// Widget for displaying AI feature action buttons
/// Extracted from project_details_screen.dart for Clean Architecture
class AIActionsBar extends StatelessWidget {
  final AIActionCallback onChatTap;
  final AIActionCallback onNotesTap;
  final AIActionCallback onFlashcardsTap;
  final AIActionCallback onQuestionsTap;

  const AIActionsBar({
    super.key,
    required this.onChatTap,
    required this.onNotesTap,
    required this.onFlashcardsTap,
    required this.onQuestionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 14, bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  tr('ai.features'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine item width for 2 columns
                final double itemWidth =
                    (constraints.maxWidth - 12) / 2; // 12 space between

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildGradientButton(
                        icon: Icons.chat_bubble_outline,
                        label: tr('ai.chat'),
                        onTap: onChatTap,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildGradientButton(
                        icon: Icons.notes,
                        label: tr('ai.notes'),
                        onTap: onNotesTap,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildGradientButton(
                        icon: Icons.quiz_outlined,
                        label: tr('ai.flashcards'),
                        onTap: onFlashcardsTap,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildGradientButton(
                        icon: Icons.help_outline,
                        label: tr('ai.questions'),
                        onTap: onQuestionsTap,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Unified Gradient Outline: Orange -> Green -> Blue -> Purple
    const gradient = LinearGradient(
      colors: [Colors.orange, Colors.green, Colors.blue, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: gradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5), // Border width
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black, // Dark background to create outline effect
            borderRadius: BorderRadius.circular(10.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gradient color or white?
                  // "Every AI Feature buttons should share the same color gradient outline"
                  // I'll keep icon/text white for contrast against black background.
                  Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
