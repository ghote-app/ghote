import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/question_service.dart';
import '../services/learning_progress_service.dart';
import '../utils/toast_utils.dart';

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
  final LearningProgressService _progressService = LearningProgressService();
  String _selectedType = 'mcq-single';
  Map<String, String?> _userAnswers = {};  // 單選題答案
  Map<String, Set<String>> _userMultiAnswers = {};  // 多選題答案
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
    String typeLabel;
    switch (questionType) {
      case 'mcq-single':
        typeLabel = '單選題';
        break;
      case 'mcq-multiple':
        typeLabel = '多選題';
        break;
      case 'open-ended':
        typeLabel = '開放式問答';
        break;
      default:
        typeLabel = '選擇題';
    }
    String selectedLanguage = 'zh';
    
    final confirmed = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '生成$typeLabel',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '將使用 AI 根據您上傳的文件內容生成 5 個$typeLabel。\n\n這可能需要一些時間，確定要繼續嗎？',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                '生成語言：',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'zh',
                      groupValue: selectedLanguage,
                      onChanged: (value) => setState(() => selectedLanguage = value!),
                      title: const Text('中文', style: TextStyle(color: Colors.white)),
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'en',
                      groupValue: selectedLanguage,
                      onChanged: (value) => setState(() => selectedLanguage = value!),
                      title: const Text('English', style: TextStyle(color: Colors.white)),
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedLanguage),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('開始生成'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null) {
      setState(() {
        _selectedType = questionType;
      });
      await _generateQuestions(confirmed);
    }
  }

  Future<void> _generateQuestions(String language) async {
    if (!mounted) return;

    String typeLabel;
    switch (_selectedType) {
      case 'mcq-single':
        typeLabel = '單選題';
        break;
      case 'mcq-multiple':
        typeLabel = '多選題';
        break;
      case 'open-ended':
        typeLabel = '開放式問答';
        break;
      default:
        typeLabel = '選擇題';
    }
    final languageText = language == 'en' ? 'English' : '中文';

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
                  '正在分析文件內容並生成練習題目 ($languageText)\n請稍候片刻',
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
        language: language,
      );
      if (!mounted) return;
      Navigator.of(context).pop();

      ToastUtils.success(
        context,
        '✓ 成功生成 ${questions.length} 個$typeLabel',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ToastUtils.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _checkAnswer(Question question, String? selectedAnswer) {
    // FR-9.2: 記錄測驗結果
    final isCorrect = selectedAnswer == question.correctAnswer;
    _recordQuizAttempt(isCorrect);
    
    setState(() {
      _userAnswers[question.id] = selectedAnswer;
      _showAnswers[question.id] = true;
    });
  }

  /// FR-9.2: 記錄測驗作答結果到學習進度
  Future<void> _recordQuizAttempt(bool isCorrect) async {
    try {
      await _progressService.recordQuizAttempt(
        projectId: widget.projectId,
        correctCount: isCorrect ? 1 : 0,
        totalQuestions: 1,
      );
    } catch (e) {
      // 靜默失敗，不影響用戶體驗
      debugPrint('記錄測驗結果失敗: $e');
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await _questionService.deleteQuestion(widget.projectId, questionId);
      if (!mounted) return;
      ToastUtils.success(
        context,
        '✓ 題目已刪除',
      );
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(
        context,
        '✗ 刪除失敗: $e',
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
        ToastUtils.success(
          context,
          '✓ 已刪除 ${questions.length} 個題目',
        );
      } catch (e) {
        if (!mounted) return;
        ToastUtils.error(
          context,
          '✗ 刪除失敗: $e',
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
                value: 'mcq-single',
                child: Text('生成單選題', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'mcq-multiple',
                child: Text('生成多選題', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'open-ended',
                child: Text('生成開放式問答', style: TextStyle(color: Colors.white)),
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
                    onPressed: () => _showGenerateConfirmation('mcq-single'),
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
    final userMultiAnswer = _userMultiAnswers[question.id] ?? <String>{};
    
    // 計算是否正確
    bool isCorrect;
    if (question.isMcqMultiple) {
      final correctSet = (question.correctAnswers ?? []).toSet();
      isCorrect = showAnswer && userMultiAnswer.length == correctSet.length &&
          userMultiAnswer.containsAll(correctSet);
    } else {
      isCorrect = userAnswer == question.correctAnswer;
    }
    
    // 獲取題型標籤
    String typeLabel;
    Color typeColor;
    if (question.isMcqSingle) {
      typeLabel = '單選題';
      typeColor = Colors.blue;
    } else if (question.isMcqMultiple) {
      typeLabel = '多選題';
      typeColor = Colors.orange;
    } else {
      typeLabel = '開放式';
      typeColor = Colors.purple;
    }

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
              // 題型標籤
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 難度標籤
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.difficultyLabel,
                  style: TextStyle(
                    color: _getDifficultyColor(question.difficulty),
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
                onPressed: () => _confirmDeleteQuestion(question.id),
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
          // 問題文字
          Text(
            question.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // 根據題型顯示不同的答題區域
          if (question.isMcqSingle && question.options != null)
            _buildSingleChoiceOptions(question, showAnswer, userAnswer),
          if (question.isMcqMultiple && question.options != null)
            _buildMultipleChoiceOptions(question, showAnswer, userMultiAnswer),
          if (question.isOpenEnded)
            _buildOpenEndedAnswer(question, showAnswer, userAnswer),
          // 顯示關鍵字（開放式問題）
          if (showAnswer && question.isOpenEnded && question.keywords != null && question.keywords!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.keywords!.map((keyword) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$keyword',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          // 解釋區域
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

  Color _getDifficultyColor(String difficulty) {
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

  Future<void> _confirmDeleteQuestion(String questionId) async {
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
      await _deleteQuestion(questionId);
    }
  }

  Widget _buildSingleChoiceOptions(Question question, bool showAnswer, String? userAnswer) {
    return Column(
      children: question.options!.map((option) {
        final isSelected = userAnswer == option;
        final isCorrectOption = option == question.correctAnswer;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: showAnswer ? null : () => _checkAnswer(question, option),
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
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: showAnswer
                        ? (isCorrectOption ? Colors.green : isSelected ? Colors.red : Colors.white54)
                        : (isSelected ? Colors.blue : Colors.white54),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  if (showAnswer && isCorrectOption)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceOptions(Question question, bool showAnswer, Set<String> userMultiAnswer) {
    final correctAnswers = (question.correctAnswers ?? []).toSet();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!showAnswer)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '（可多選，選擇完畢後點擊送出）',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ...question.options!.map((option) {
          final isSelected = userMultiAnswer.contains(option);
          final isCorrectOption = correctAnswers.contains(option);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: showAnswer ? null : () {
                setState(() {
                  final current = _userMultiAnswers[question.id] ?? <String>{};
                  if (current.contains(option)) {
                    current.remove(option);
                  } else {
                    current.add(option);
                  }
                  _userMultiAnswers[question.id] = current;
                });
              },
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
                          ? Colors.orange.withValues(alpha: 0.2)
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
                            ? Colors.orange
                            : Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: showAnswer
                          ? (isCorrectOption ? Colors.green : isSelected ? Colors.red : Colors.white54)
                          : (isSelected ? Colors.orange : Colors.white54),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    if (showAnswer && isCorrectOption)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    if (showAnswer && isSelected && !isCorrectOption)
                      const Icon(Icons.cancel, color: Colors.red, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        if (!showAnswer)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: userMultiAnswer.isEmpty ? null : () {
                // FR-9.2: 記錄多選題測驗結果
                final correctSet = (question.correctAnswers ?? []).toSet();
                final isCorrect = userMultiAnswer.length == correctSet.length &&
                    userMultiAnswer.containsAll(correctSet);
                _recordQuizAttempt(isCorrect);
                
                setState(() {
                  _showAnswers[question.id] = true;
                });
              },
              icon: const Icon(Icons.send),
              label: const Text('送出答案'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOpenEndedAnswer(Question question, bool showAnswer, String? userAnswer) {
    if (!showAnswer) {
      return Column(
        children: [
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
                  ToastUtils.warning(context, '請輸入答案');
                  return;
                }
                _checkAnswer(question, answer);
              },
              icon: const Icon(Icons.send),
              label: const Text('送出答案'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
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
    );
  }
}

