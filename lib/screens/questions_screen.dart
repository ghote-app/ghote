import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/question_service.dart';
import '../utils/toast_utils.dart';
import 'quiz_screen.dart';

/// 題目管理畫面
/// - 生成題目
/// - 查看題目列表
/// - 刪除題目
/// - 進入測驗模式
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
  String _filterType = 'all'; // 'all' | 'mcq-single' | 'mcq-multiple' | 'open-ended'

  /// 進入測驗模式
  void _startQuiz(List<Question> questions, {String? questionType}) {
    List<Question> filteredQuestions;
    if (questionType != null && questionType != 'all') {
      filteredQuestions = questions.where((q) => q.questionType == questionType).toList();
    } else {
      filteredQuestions = questions;
    }

    if (filteredQuestions.isEmpty) {
      ToastUtils.warning(context, '沒有可測驗的題目');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          projectId: widget.projectId,
          questions: filteredQuestions,
        ),
      ),
    );
  }

  /// 顯示測驗類型選擇對話框
  Future<void> _showQuizTypeDialog(List<Question> questions) async {
    final singleCount = questions.where((q) => q.isMcqSingle).length;
    final multiCount = questions.where((q) => q.isMcqMultiple).length;
    final openCount = questions.where((q) => q.isOpenEnded).length;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('選擇測驗類型', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuizTypeOption('all', '全部題目', Icons.quiz, Colors.blue, questions.length),
            if (singleCount > 0)
              _buildQuizTypeOption('mcq-single', '單選題', Icons.radio_button_checked, Colors.blue, singleCount),
            if (multiCount > 0)
              _buildQuizTypeOption('mcq-multiple', '多選題', Icons.check_box, Colors.orange, multiCount),
            if (openCount > 0)
              _buildQuizTypeOption('open-ended', '問答題', Icons.edit_note, Colors.purple, openCount),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );

    if (result != null) {
      _startQuiz(questions, questionType: result);
    }
  }

  Widget _buildQuizTypeOption(String type, String label, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$count 題', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('生成$typeLabel', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '將使用 AI 根據您上傳的文件內容生成 5 個$typeLabel。\n\n這可能需要一些時間，確定要繼續嗎？',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text('生成語言：', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLanguageOption('zh', '中文', selectedLanguage, (v) => setState(() => selectedLanguage = v)),
                  const SizedBox(width: 16),
                  _buildLanguageOption('en', 'English', selectedLanguage, (v) => setState(() => selectedLanguage = v)),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('開始生成'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null) {
      await _generateQuestions(questionType, confirmed);
    }
  }

  Widget _buildLanguageOption(String value, String label, String groupValue, Function(String) onChanged) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.blue : Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blue : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQuestions(String questionType, String language) async {
    if (!mounted) return;

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
    final languageText = language == 'en' ? 'English' : '中文';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  'AI 正在生成$typeLabel...',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '正在分析文件內容並生成練習題目 ($languageText)\n請稍候片刻',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
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
        questionType: questionType,
        count: 5,
        language: language,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ToastUtils.success(context, '✓ 成功生成 ${questions.length} 個$typeLabel');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ToastUtils.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await _questionService.deleteQuestion(widget.projectId, questionId);
      if (!mounted) return;
      ToastUtils.success(context, '✓ 題目已刪除');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, '✗ 刪除失敗: $e');
    }
  }

  Future<void> _deleteAllQuestions(List<Question> questions) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('刪除所有題目', style: TextStyle(color: Colors.white)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
        ToastUtils.success(context, '✓ 已刪除 ${questions.length} 個題目');
      } catch (e) {
        if (!mounted) return;
        ToastUtils.error(context, '✗ 刪除失敗: $e');
      }
    }
  }

  Future<void> _confirmDeleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('刪除題目', style: TextStyle(color: Colors.white)),
        content: const Text('確定要刪除這個題目嗎？', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteQuestion(questionId);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('練習問題', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 開始測驗按鈕
          StreamBuilder<List<Question>>(
            stream: _questionService.watchQuestions(widget.projectId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.green),
                onPressed: () => _showQuizTypeDialog(snapshot.data!),
                tooltip: '開始測驗',
              );
            },
          ),
          // 刪除所有按鈕
          StreamBuilder<List<Question>>(
            stream: _questionService.watchQuestions(widget.projectId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
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
            onSelected: (value) => _showGenerateConfirmation(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'mcq-single', child: Text('生成單選題', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'mcq-multiple', child: Text('生成多選題', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'open-ended', child: Text('生成開放式問答', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Question>>(
        stream: _questionService.watchQuestions(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final allQuestions = snapshot.data!;
          if (allQuestions.isEmpty) {
            return _buildEmptyState();
          }

          // 根據篩選條件過濾題目
          final questions = _filterType == 'all'
              ? allQuestions
              : allQuestions.where((q) => q.questionType == _filterType).toList();

          return Column(
            children: [
              // 題型篩選標籤
              _buildFilterTabs(allQuestions),
              // 開始測驗按鈕
              if (questions.isNotEmpty) _buildStartQuizButton(questions),
              // 題目列表
              Expanded(
                child: questions.isEmpty
                    ? Center(
                        child: Text(
                          '沒有此類型的題目',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) => _buildQuestionCard(questions[index], index + 1, questions.length),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('還沒有問題', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showGenerateConfirmation('mcq-single'),
            icon: const Icon(Icons.add),
            label: const Text('生成問題'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<Question> allQuestions) {
    final singleCount = allQuestions.where((q) => q.isMcqSingle).length;
    final multiCount = allQuestions.where((q) => q.isMcqMultiple).length;
    final openCount = allQuestions.where((q) => q.isOpenEnded).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', '全部', allQuestions.length, Colors.blue),
            const SizedBox(width: 8),
            _buildFilterChip('mcq-single', '單選題', singleCount, Colors.blue),
            const SizedBox(width: 8),
            _buildFilterChip('mcq-multiple', '多選題', multiCount, Colors.orange),
            const SizedBox(width: 8),
            _buildFilterChip('open-ended', '問答題', openCount, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, int count, Color color) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartQuizButton(List<Question> questions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _startQuiz(questions),
          icon: const Icon(Icons.play_arrow),
          label: Text('開始測驗 (${questions.length} 題)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  /// 簡化版題目卡片 - 只顯示題目資訊，不提供作答功能
  Widget _buildQuestionCard(Question question, int index, int total) {
    String typeLabel;
    Color typeColor;
    if (question.isMcqSingle) {
      typeLabel = '單選題';
      typeColor = Colors.blue;
    } else if (question.isMcqMultiple) {
      typeLabel = '多選題';
      typeColor = Colors.orange;
    } else {
      typeLabel = '問答題';
      typeColor = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => _startQuiz([question]),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標籤列
              Row(
                children: [
                  // 題號
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$index/$total',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 題型標籤
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(typeLabel, style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w600)),
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
                      style: TextStyle(color: _getDifficultyColor(question.difficulty), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  // 刪除按鈕
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.withValues(alpha: 0.7)),
                    onPressed: () => _confirmDeleteQuestion(question.id),
                    tooltip: '刪除題目',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 問題文字
              Text(
                question.questionText,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 點擊提示
              Row(
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.white.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    '點擊開始測驗此題',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
