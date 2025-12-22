import 'package:flutter/material.dart';
import '../../../../utils/app_locale.dart';

/// Widget displaying quiz type label (single choice, multiple choice, open-ended)
class QuizTypeLabel extends StatelessWidget {
  const QuizTypeLabel({
    super.key,
    required this.isMcqSingle,
    required this.isMcqMultiple,
    required this.isOpenEnded,
  });

  final bool isMcqSingle;
  final bool isMcqMultiple;
  final bool isOpenEnded;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    
    if (isMcqSingle) {
      label = tr('quiz.singleChoice');
      color = Colors.blue;
    } else if (isMcqMultiple) {
      label = tr('quiz.multipleChoice');
      color = Colors.orange;
    } else {
      label = tr('quiz.openEnded');
      color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Widget displaying difficulty label
class QuizDifficultyLabel extends StatelessWidget {
  const QuizDifficultyLabel({
    super.key,
    required this.difficulty,
    required this.difficultyLabel,
  });

  final String difficulty;
  final String difficultyLabel;

  Color get _color {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficultyLabel,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
