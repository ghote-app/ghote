import 'package:flutter/material.dart';
import '../../../../models/question.dart';
import 'quiz_feedback.dart';

/// FR-7: Open-ended question answer area
class OpenEndedQuestion extends StatelessWidget {
  const OpenEndedQuestion({
    super.key,
    required this.question,
    required this.showAnswer,
    required this.showReference,
    required this.userAnswer,
    required this.textController,
    required this.onSubmit,
    required this.onToggleReference,
  });

  final Question question;
  final bool showAnswer;
  final bool showReference;
  final String? userAnswer;
  final TextEditingController textController;
  final VoidCallback onSubmit;
  final VoidCallback onToggleReference;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FR-7.4: Keyword hints
        if (question.keywords != null && question.keywords!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '關鍵字提示：',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: question.keywords!.map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '#$keyword',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        if (!showAnswer) ...[
          // Answer input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: '請輸入您的答案...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.send),
              label: const Text('送出答案'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          // Display user's answer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '您的答案',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  userAnswer ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // FR-7.3: Toggle reference answer
          InkWell(
            onTap: onToggleReference,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '參考答案',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        showReference ? Icons.expand_less : Icons.expand_more,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  if (showReference) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      question.correctAnswer ?? '無參考答案',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // FR-6.5: Explanation (if available)
        if (showAnswer && question.explanation != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: QuizFeedback(
              isCorrect: true, // Open-ended doesn't have true/false
              explanation: question.explanation,
            ),
          ),
      ],
    );
  }
}
