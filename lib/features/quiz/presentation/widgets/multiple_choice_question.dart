import 'package:flutter/material.dart';
import '../../../../models/question.dart';
import 'quiz_feedback.dart';

/// FR-6.3: Multiple choice question answer area
class MultipleChoiceQuestion extends StatelessWidget {
  const MultipleChoiceQuestion({
    super.key,
    required this.question,
    required this.showAnswer,
    required this.userAnswers,
    required this.isCorrect,
    required this.onToggleAnswer,
    required this.onSubmit,
  });

  final Question question;
  final bool showAnswer;
  final Set<String> userAnswers;
  final bool? isCorrect;
  final void Function(String option) onToggleAnswer;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final correctAnswers = (question.correctAnswers ?? []).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!showAnswer)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '本題為多選題，請選擇所有正確答案後點擊送出',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

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
          final optionLabel = String.fromCharCode(65 + index);
          final isSelected = userAnswers.contains(option);
          final isCorrectOption = correctAnswers.contains(option);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: showAnswer ? null : () => onToggleAnswer(option),
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
                    // Checkbox
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (showAnswer
                                ? (isCorrectOption ? Colors.green : Colors.red)
                                : Colors.orange)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? (showAnswer
                                  ? (isCorrectOption ? Colors.green : Colors.red)
                                  : Colors.orange)
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Option label
                    Text(
                      '$optionLabel.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
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

        // Submit button
        if (!showAnswer)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: userAnswers.isEmpty ? null : onSubmit,
                icon: const Icon(Icons.send),
                label: const Text('送出答案'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
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
}
