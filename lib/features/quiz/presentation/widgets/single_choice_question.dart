import 'package:flutter/material.dart';
import '../../../../models/question.dart';
import 'quiz_feedback.dart';

/// FR-6.3: Single choice question answer area
class SingleChoiceQuestion extends StatelessWidget {
  const SingleChoiceQuestion({
    super.key,
    required this.question,
    required this.showAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.onSelectAnswer,
  });

  final Question question;
  final bool showAnswer;
  final String? userAnswer;
  final bool? isCorrect;
  final void Function(String answer) onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FR-6.4: Result feedback
        if (showAnswer)
          QuizFeedback(
            isCorrect: isCorrect ?? false,
            explanation: question.explanation,
          ),
        
        // Options list
        ...question.options!.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
          final isSelected = userAnswer == option;
          final isCorrectOption = option == question.correctAnswer;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: showAnswer ? null : () => onSelectAnswer(option),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getOptionBackgroundColor(showAnswer, isSelected, isCorrectOption),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getOptionBorderColor(showAnswer, isSelected, isCorrectOption),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Option label
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getOptionLabelColor(showAnswer, isSelected, isCorrectOption),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Option text
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Correct/incorrect icons
                    if (showAnswer && isCorrectOption)
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    if (showAnswer && isSelected && !isCorrectOption)
                      const Icon(Icons.cancel, color: Colors.red, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getOptionBackgroundColor(bool showAnswer, bool isSelected, bool isCorrectOption) {
    if (!showAnswer) {
      return isSelected
          ? Colors.blue.withValues(alpha: 0.15)
          : Colors.white.withValues(alpha: 0.05);
    }
    if (isCorrectOption) {
      return Colors.green.withValues(alpha: 0.15);
    }
    if (isSelected) {
      return Colors.red.withValues(alpha: 0.15);
    }
    return Colors.white.withValues(alpha: 0.05);
  }

  Color _getOptionBorderColor(bool showAnswer, bool isSelected, bool isCorrectOption) {
    if (!showAnswer) {
      return isSelected
          ? Colors.blue
          : Colors.white.withValues(alpha: 0.1);
    }
    if (isCorrectOption) {
      return Colors.green;
    }
    if (isSelected) {
      return Colors.red;
    }
    return Colors.white.withValues(alpha: 0.1);
  }

  Color _getOptionLabelColor(bool showAnswer, bool isSelected, bool isCorrectOption) {
    if (!showAnswer) {
      return isSelected ? Colors.blue : Colors.white.withValues(alpha: 0.3);
    }
    if (isCorrectOption) {
      return Colors.green;
    }
    if (isSelected) {
      return Colors.red;
    }
    return Colors.white.withValues(alpha: 0.3);
  }
}
