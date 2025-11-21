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
  Map<String, TextEditingController> _textControllers = {};

  @override
  void dispose() {
    // 清理所有文字控制器
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _showGenerateConfirmation(String questionType) async {
    final typeLabel = questionType == 'mcq' ? '選擇題' : '開放式問題';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '生成$typeLabel',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '將使用 AI 根據您上傳的文件內容生成 5 個$typeLabel。\n\n這可能需要一些時間，確定要繼續嗎？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('開始生成'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _selectedType = questionType;
      });
      await _generateQuestions();
    }
  }

  Future<void> _generateQuestions() async {
    if (!mounted) return;

    final typeLabel = _selectedType == 'mcq' ? '選擇題' : '開放式問題';

    // 顯示更詳細的生成中對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  'AI 正在生成$typeLabel...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '正在分析文件內容並生成練習題目\n請稍候片刻',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          content: Text('✓ 成功生成 ${questions.length} 個$typeLabel'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ 生成失敗: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await _questionService.deleteQuestion(widget.projectId, questionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ 題目已刪除'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ 刪除失敗: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAllQuestions(List<Question> questions) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '刪除所有題目',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '確定要刪除所有 ${questions.length} 個題目嗎？此操作無法復原。',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('全部刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (var question in questions) {
          await _questionService.deleteQuestion(widget.projectId, question.id);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ 已刪除 ${questions.length} 個題目'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ 刪除失敗: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          // 刪除所有按鈕
          StreamBuilder<List<Question>>(
            stream: _questionService.watchQuestions(widget.projectId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: () => _deleteAllQuestions(snapshot.data!),
                tooltip: '刪除所有題目',
              );
            },
          ),
          // 生成題目按鈕
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (value) {
              _showGenerateConfirmation(value);
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
                    onPressed: () => _showGenerateConfirmation('mcq'),
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
              // 刪除按鈕
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red.withValues(alpha: 0.7),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        '刪除題目',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        '確定要刪除這個題目嗎？',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消', style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('刪除'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await _deleteQuestion(question.id);
                  }
                },
                tooltip: '刪除題目',
              ),
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
          if (question.isOpenEnded && !showAnswer) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: _textControllers.putIfAbsent(
                  question.id,
                  () => TextEditingController(),
                ),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '輸入您的答案...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final answer = _textControllers[question.id]?.text ?? '';
                  if (answer.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('請輸入答案'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _checkAnswer(question, answer);
                },
                icon: const Icon(Icons.send),
                label: const Text('送出答案'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (question.isOpenEnded && showAnswer) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '您的答案：',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userAnswer ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  const Text(
                    '參考答案：',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.correctAnswer ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
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

