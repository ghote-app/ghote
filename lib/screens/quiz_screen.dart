import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/question_service.dart';
import '../utils/toast_utils.dart';

/// FR-6 選擇題測驗畫面
/// FR-7 問答題功能畫面
class QuizScreen extends StatefulWidget {
  final String projectId;
  final List<Question> questions;
  final String? fileId; // 可選：篩選特定文件的題目

  const QuizScreen({
    super.key,
    required this.projectId,
    required this.questions,
    this.fileId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuestionService _questionService = QuestionService();
  final PageController _pageController = PageController();
  
  late List<Question> _questions;
  int _currentIndex = 0;
  
  // FR-6.8: 記錄作答結果
  final Map<String, bool?> _answerResults = {}; // questionId -> isCorrect (null = 未作答)
  final Map<String, String?> _userAnswers = {}; // 單選題答案
  final Map<String, Set<String>> _userMultiAnswers = {}; // 多選題答案
  final Map<String, String?> _userOpenAnswers = {}; // 開放式問答答案
  final Map<String, bool> _showAnswers = {}; // 是否顯示答案
  final Map<String, bool> _showReferenceAnswer = {}; // FR-7.3: 是否展開參考答案
  
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _questions = widget.questions;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// FR-6.6 / FR-7.6: 切換到下一題
  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// FR-6.6 / FR-7.6: 切換到上一題
  void _previousQuestion() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// FR-6.3 & FR-6.4: 選擇答案並顯示回饋
  void _selectAnswer(Question question, String answer) {
    if (_showAnswers[question.id] == true) return; // 已作答不能再選

    setState(() {
      _userAnswers[question.id] = answer;
      _showAnswers[question.id] = true;
      
      // FR-6.8: 記錄結果
      final isCorrect = answer == question.correctAnswer;
      _answerResults[question.id] = isCorrect;
      
      // 保存到 Firestore
      _saveAnswerResult(question.id, isCorrect);
    });
  }

  /// FR-6.3 & FR-6.4: 多選題選擇
  void _toggleMultiAnswer(Question question, String option) {
    if (_showAnswers[question.id] == true) return;

    setState(() {
      final current = _userMultiAnswers[question.id] ?? <String>{};
      if (current.contains(option)) {
        current.remove(option);
      } else {
        current.add(option);
      }
      _userMultiAnswers[question.id] = current;
    });
  }

  /// 提交多選題答案
  void _submitMultiAnswer(Question question) {
    final userAnswers = _userMultiAnswers[question.id] ?? <String>{};
    if (userAnswers.isEmpty) {
      ToastUtils.warning(context, '請至少選擇一個選項');
      return;
    }

    setState(() {
      _showAnswers[question.id] = true;
      
      // FR-6.8: 檢查並記錄結果
      final correctSet = (question.correctAnswers ?? []).toSet();
      final isCorrect = userAnswers.length == correctSet.length &&
          userAnswers.containsAll(correctSet);
      _answerResults[question.id] = isCorrect;
      
      _saveAnswerResult(question.id, isCorrect);
    });
  }

  /// FR-7.3: 展開/收起參考答案
  void _toggleReferenceAnswer(String questionId) {
    setState(() {
      _showReferenceAnswer[questionId] = !(_showReferenceAnswer[questionId] ?? false);
    });
  }

  /// 提交開放式問答
  void _submitOpenAnswer(Question question) {
    final answer = _textControllers[question.id]?.text ?? '';
    if (answer.trim().isEmpty) {
      ToastUtils.warning(context, '請輸入答案');
      return;
    }

    setState(() {
      _userOpenAnswers[question.id] = answer;
      _showAnswers[question.id] = true;
      // 開放式問答不自動評分
      _answerResults[question.id] = null;
    });
  }

  /// FR-6.8: 保存作答結果到 Firestore
  Future<void> _saveAnswerResult(String questionId, bool isCorrect) async {
    try {
      await _questionService.updateAnswerResult(
        widget.projectId,
        questionId,
        isCorrect,
      );
    } catch (e) {
      debugPrint('保存作答結果失敗: $e');
    }
  }

  /// 獲取難度顏色
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

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('測驗', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '沒有題目可以測驗',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('測驗模式', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 顯示答題進度統計
          _buildProgressStats(),
        ],
      ),
      body: Column(
        children: [
          // FR-6.2: 進度指示器
          _buildProgressIndicator(),
          // 題目內容
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return _buildQuestionPage(question, index);
              },
            ),
          ),
          // FR-6.6 / FR-7.6: 導航按鈕
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  /// 答題進度統計
  Widget _buildProgressStats() {
    final answered = _answerResults.values.where((r) => r != null).length;
    final correct = _answerResults.values.where((r) => r == true).length;
    
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            '$correct/$answered',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// FR-6.2: 進度指示器
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              // 題號/總數
              Text(
                '第 ${_currentIndex + 1} 題 / 共 ${_questions.length} 題',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // 題型與難度
              Row(
                children: [
                  _buildTypeLabel(_questions[_currentIndex]),
                  const SizedBox(width: 8),
                  _buildDifficultyLabel(_questions[_currentIndex]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // 題目圓點指示器
          _buildDotIndicator(),
        ],
      ),
    );
  }

  /// 題目圓點指示器
  Widget _buildDotIndicator() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_questions.length, (index) {
          final question = _questions[index];
          final result = _answerResults[question.id];
          final isCurrentQuestion = index == _currentIndex;
          
          Color dotColor;
          if (result == true) {
            dotColor = Colors.green;
          } else if (result == false) {
            dotColor = Colors.red;
          } else if (_showAnswers[question.id] == true) {
            dotColor = Colors.grey; // 開放式已作答
          } else {
            dotColor = Colors.white.withValues(alpha: 0.3);
          }

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: isCurrentQuestion ? 12 : 8,
              height: isCurrentQuestion ? 12 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: isCurrentQuestion
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 題型標籤
  Widget _buildTypeLabel(Question question) {
    String label;
    Color color;
    
    if (question.isMcqSingle) {
      label = '單選';
      color = Colors.blue;
    } else if (question.isMcqMultiple) {
      label = '多選';
      color = Colors.orange;
    } else {
      label = '問答';
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

  /// FR-6.7 / FR-7.5: 難度標籤
  Widget _buildDifficultyLabel(Question question) {
    final color = _getDifficultyColor(question.difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        question.difficultyLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 題目頁面
  Widget _buildQuestionPage(Question question, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FR-6.2 / FR-7.2: 問題文字
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${index + 1}.',
                  style: TextStyle(
                    color: Colors.blue.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  question.questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 根據題型顯示不同的答題區域
          if (question.isMcqSingle)
            _buildSingleChoiceArea(question),
          if (question.isMcqMultiple)
            _buildMultipleChoiceArea(question),
          if (question.isOpenEnded)
            _buildOpenEndedArea(question),
        ],
      ),
    );
  }

  /// FR-6.3: 單選題選項區域
  Widget _buildSingleChoiceArea(Question question) {
    final showAnswer = _showAnswers[question.id] ?? false;
    final userAnswer = _userAnswers[question.id];
    final isCorrect = _answerResults[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FR-6.4: 正確/錯誤回饋
        if (showAnswer)
          _buildResultFeedback(isCorrect ?? false),
        
        // 選項列表
        ...question.options!.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
          final isSelected = userAnswer == option;
          final isCorrectOption = option == question.correctAnswer;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: showAnswer ? null : () => _selectAnswer(question, option),
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
                    // 選項字母
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
                    // 選項文字
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // 正確/錯誤圖標
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

        // FR-6.5: 詳細解析
        if (showAnswer && question.explanation != null)
          _buildExplanation(question.explanation!),
      ],
    );
  }

  /// FR-6.3: 多選題選項區域
  Widget _buildMultipleChoiceArea(Question question) {
    final showAnswer = _showAnswers[question.id] ?? false;
    final userAnswers = _userMultiAnswers[question.id] ?? <String>{};
    final correctAnswers = (question.correctAnswers ?? []).toSet();
    final isCorrect = _answerResults[question.id];

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

        // FR-6.4: 正確/錯誤回饋
        if (showAnswer)
          _buildResultFeedback(isCorrect ?? false),

        // 選項列表
        ...question.options!.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final optionLabel = String.fromCharCode(65 + index);
          final isSelected = userAnswers.contains(option);
          final isCorrectOption = correctAnswers.contains(option);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: showAnswer ? null : () => _toggleMultiAnswer(question, option),
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
                    // 勾選框
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
                    // 選項字母
                    Text(
                      '$optionLabel.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 選項文字
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // 正確/錯誤圖標
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

        // 送出按鈕
        if (!showAnswer)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: userAnswers.isEmpty ? null : () => _submitMultiAnswer(question),
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

        // FR-6.5: 詳細解析
        if (showAnswer && question.explanation != null)
          _buildExplanation(question.explanation!),
      ],
    );
  }

  /// FR-7: 開放式問答區域
  Widget _buildOpenEndedArea(Question question) {
    final showAnswer = _showAnswers[question.id] ?? false;
    final showReference = _showReferenceAnswer[question.id] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FR-7.4: 關鍵字標籤
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
          // 答案輸入區
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: TextField(
              controller: _textControllers.putIfAbsent(
                question.id,
                () => TextEditingController(),
              ),
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
          // 送出按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitOpenAnswer(question),
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
          // 顯示用戶答案
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
                  _userOpenAnswers[question.id] ?? '',
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
          
          // FR-7.3: 展開參考答案按鈕
          InkWell(
            onTap: () => _toggleReferenceAnswer(question.id),
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

        // FR-6.5: 詳細解析（如果有）
        if (showAnswer && question.explanation != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildExplanation(question.explanation!),
          ),
      ],
    );
  }

  /// FR-6.4: 正確/錯誤回饋
  Widget _buildResultFeedback(bool isCorrect) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? '答對了！' : '答錯了！',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCorrect ? '繼續保持！' : '請查看正確答案和解析',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FR-6.5: 解析區域
  Widget _buildExplanation(String explanation) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                '解析',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            explanation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 選項背景顏色
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

  /// 選項邊框顏色
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

  /// 選項標籤顏色
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

  /// FR-6.6 / FR-7.6: 導航按鈕
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // 上一題
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentIndex > 0 ? _previousQuestion : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('上一題'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: _currentIndex > 0
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 下一題
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentIndex < _questions.length - 1 ? _nextQuestion : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('下一題'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
