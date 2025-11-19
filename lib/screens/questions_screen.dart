import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/question_service.dart';

class QuestionsScreen extends StatefulWidget {
  final String projectId;

  const QuestionsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final QuestionService _questionService = QuestionService();
  String _selectedType = 'mcq';
  Map<String, String?> _userAnswers = {};
  Map<String, bool> _showAnswers = {};

  Future<void> _generateQuestions() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final questions = await _questionService.generateQuestions(
        projectId: widget.projectId,
        questionType: _selectedType,
        count: 5,
      );
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功生成 ${questions.length} 個問題'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkAnswer(Question question, String? selectedAnswer) {
    setState(() {
      _userAnswers[question.id] = selectedAnswer;
      _showAnswers[question.id] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('練習問題', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (value) {
              setState(() {
                _selectedType = value;
              });
              _generateQuestions();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mcq',
                child: Text('生成選擇題', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'open-ended',
                child: Text('生成開放式問題', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Question>>(
        stream: _questionService.watchQuestions(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final questions = snapshot.data!;
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有問題',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _generateQuestions,
                    icon: const Icon(Icons.add),
                    label: const Text('生成問題'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return _buildQuestionCard(question);
            },
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final showAnswer = _showAnswers[question.id] ?? false;
    final userAnswer = _userAnswers[question.id];
    final isCorrect = userAnswer == question.correctAnswer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showAnswer
              ? (isCorrect
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.red.withValues(alpha: 0.5))
              : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: question.isMcq
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.isMcq ? '選擇題' : '開放式',
                  style: TextStyle(
                    color: question.isMcq ? Colors.blue : Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (showAnswer)
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (question.isMcq && question.options != null)
            ...question.options!.map((option) {
              final isSelected = userAnswer == option;
              final isCorrectOption = option == question.correctAnswer;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: showAnswer
                      ? null
                      : () => _checkAnswer(question, option),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: showAnswer
                          ? (isCorrectOption
                              ? Colors.green.withValues(alpha: 0.2)
                              : isSelected
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05))
                          : (isSelected
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: showAnswer
                            ? (isCorrectOption
                                ? Colors.green
                                : isSelected
                                    ? Colors.red
                                    : Colors.white.withValues(alpha: 0.1))
                            : (isSelected
                                ? Colors.blue
                                : Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (showAnswer && isCorrectOption)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                        if (showAnswer && isSelected && !isCorrectOption)
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          if (question.isOpenEnded && !showAnswer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '輸入您的答案...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                maxLines: 3,
              ),
            ),
          if (question.isOpenEnded && showAnswer)
            ElevatedButton(
              onPressed: () => _checkAnswer(question, userAnswer),
              child: const Text('提交答案'),
            ),
          if (showAnswer && question.explanation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '解釋：',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.explanation!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

