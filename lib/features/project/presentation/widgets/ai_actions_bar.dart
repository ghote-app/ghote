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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.6), size: 18),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: tr('ai.chat'),
                onTap: onChatTap,
              ),
              _buildActionButton(
                icon: Icons.notes,
                label: tr('ai.notes'),
                onTap: onNotesTap,
              ),
              _buildActionButton(
                icon: Icons.quiz_outlined,
                label: tr('ai.flashcards'),
                onTap: onFlashcardsTap,
              ),
              _buildActionButton(
                icon: Icons.help_outline,
                label: tr('ai.questions'),
                onTap: onQuestionsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
