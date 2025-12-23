import 'package:flutter/material.dart';
import '../../../../utils/app_locale.dart';

/// Widget displaying flashcard learning progress stats
class FlashcardProgressHeader extends StatelessWidget {
  const FlashcardProgressHeader({
    super.key,
    required this.currentIndex,
    required this.totalCards,
    required this.mastered,
    required this.review,
    required this.difficult,
    required this.unlearned,
    this.currentCardStatus,
    this.currentCardStatusLabel,
  });

  final int currentIndex;
  final int totalCards;
  final int mastered;
  final int review;
  final int difficult;
  final int unlearned;
  final String? currentCardStatus;
  final String? currentCardStatusLabel;

  double get _progress => totalCards > 0 ? mastered / totalCards : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tr("flashcards.card")} ${currentIndex + 1} / $totalCards',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (currentCardStatus != null && currentCardStatusLabel != null)
                _buildStatusLabel(),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(tr('flashcards.mastered'), mastered, Colors.green),
              _buildStatItem(tr('flashcards.review'), review, Colors.orange),
              _buildStatItem(tr('flashcards.difficult'), difficult, Colors.red),
              _buildStatItem(tr('flashcards.unlearned'), unlearned, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLabel() {
    // Parse color from status
    Color color;
    switch (currentCardStatus) {
      case 'mastered':
        color = Colors.green;
        break;
      case 'review':
        color = Colors.orange;
        break;
      case 'difficult':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        currentCardStatusLabel!,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
