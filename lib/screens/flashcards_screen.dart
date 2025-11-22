import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../utils/toast_utils.dart';

class FlashcardsScreen extends StatefulWidget {
  final String projectId;

  const FlashcardsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService();
  late AnimationController _flipController;
  bool _isFlipped = false;
  int _currentIndex = 0;
  List<Flashcard> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _showGenerateConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '生成抽認卡',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '將使用 AI 根據您上傳的文件內容生成 10 張抽認卡。\n\n這可能需要一些時間，確定要繼續嗎？',
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('開始生成'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _generateFlashcards();
    }
  }

  Future<void> _generateFlashcards() async {
    if (!mounted) return;
    
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
                const Text(
                  'AI 正在生成抽認卡...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '正在分析文件內容並生成學習卡片\n請稍候片刻',
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
      final flashcards = await _flashcardService.generateFlashcards(
        projectId: widget.projectId,
        count: 10,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      
      // 重置為新生成的抽認卡（不包含舊的）
      setState(() {
        _flashcards = flashcards;
        _currentIndex = 0;
        _isFlipped = false;
      });
      
      ToastUtils.success(
        context,
        '✓ 成功生成 ${flashcards.length} 個抽認卡',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ToastUtils.error(
        context,
        '✗ 生成失敗: $e',
      );
    }
  }

  Future<void> _deleteFlashcard(String flashcardId) async {
    try {
      await _flashcardService.deleteFlashcard(widget.projectId, flashcardId);
      
      // 更新本地列表
      setState(() {
        _flashcards.removeWhere((f) => f.id == flashcardId);
        if (_currentIndex >= _flashcards.length && _flashcards.isNotEmpty) {
          _currentIndex = _flashcards.length - 1;
        }
        if (_flashcards.isEmpty) {
          _currentIndex = 0;
        }
      });
      
      if (!mounted) return;
      ToastUtils.success(
        context,
        '✓ 抽認卡已刪除',
      );
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(
        context,
        '✗ 刪除失敗: $e',
      );
    }
  }

  Future<void> _deleteAllFlashcards(List<Flashcard> flashcards) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '刪除所有抽認卡',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '確定要刪除所有 ${flashcards.length} 張抽認卡嗎？此操作無法復原。',
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
        for (var flashcard in flashcards) {
          await _flashcardService.deleteFlashcard(widget.projectId, flashcard.id);
        }
        
        setState(() {
          _flashcards.clear();
          _currentIndex = 0;
        });
        
        if (!mounted) return;
        ToastUtils.success(
          context,
          '✓ 已刪除 ${flashcards.length} 張抽認卡',
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

  void _flipCard() {
    if (_flipController.isAnimating) return;
    setState(() {
      _isFlipped = !_isFlipped;
    });
    if (_isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  Future<void> _updateMastery(double mastery) async {
    if (_currentIndex >= _flashcards.length) return;
    final flashcard = _flashcards[_currentIndex];
    try {
      await _flashcardService.updateReviewStatus(
        widget.projectId,
        flashcard.id,
        masteryLevel: mastery,
      );
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(
        context,
        '更新失敗: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('抽認卡', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 刪除所有按鈕
          StreamBuilder<List<Flashcard>>(
            stream: _flashcardService.watchFlashcards(widget.projectId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: () => _deleteAllFlashcards(snapshot.data!),
                tooltip: '刪除所有抽認卡',
              );
            },
          ),
          // 生成抽認卡按鈕
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showGenerateConfirmation,
            tooltip: '生成抽認卡',
          ),
        ],
      ),
      body: StreamBuilder<List<Flashcard>>(
        stream: _flashcardService.watchFlashcards(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final flashcards = snapshot.data!;
          if (flashcards.isEmpty) {
            return Center(
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
                    '還沒有抽認卡',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showGenerateConfirmation,
                    icon: const Icon(Icons.add),
                    label: const Text('生成抽認卡'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // 同步 StreamBuilder 的資料到本地狀態
          if (_flashcards.isEmpty || _flashcards.length != flashcards.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _flashcards = flashcards;
                  if (_currentIndex >= _flashcards.length) {
                    _currentIndex = 0;
                  }
                });
              }
            });
          }

          if (_currentIndex >= _flashcards.length) {
            _currentIndex = 0;
          }
          
          if (_flashcards.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final currentCard = _flashcards[_currentIndex];

          return Column(
            children: [
              // 進度指示器
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${_flashcards.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _flashcards.length,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 刪除當前卡片按鈕
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
                              '刪除抽認卡',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              '確定要刪除這張抽認卡嗎？',
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
                          await _deleteFlashcard(currentCard.id);
                        }
                      },
                      tooltip: '刪除此卡',
                    ),
                  ],
                ),
              ),
              // 抽認卡
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _flipController,
                      builder: (context, child) {
                        final angle = _flipController.value * 3.14159;
                        final isFront = angle < 1.5708;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: Transform(
                            // 當背面時，再翻轉一次讓文字正常顯示
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(isFront ? 0 : 3.14159),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.5,
                              decoration: BoxDecoration(
                                color: isFront
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isFront
                                      ? Colors.blue.withValues(alpha: 0.5)
                                      : Colors.green.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    isFront ? currentCard.question : currentCard.answer,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 控制按鈕
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _flipCard();
                      },
                      icon: Icon(_isFlipped ? Icons.refresh : Icons.flip),
                      label: Text(_isFlipped ? '查看問題' : '查看答案'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed:
                          _currentIndex < _flashcards.length - 1 ? _nextCard : null,
                    ),
                  ],
                ),
              ),
              // 掌握程度按鈕
              if (_isFlipped)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMasteryButton('困難', 0.0, Colors.red),
                      _buildMasteryButton('一般', 0.5, Colors.orange),
                      _buildMasteryButton('簡單', 1.0, Colors.green),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMasteryButton(String label, double mastery, Color color) {
    return ElevatedButton(
      onPressed: () {
        _updateMastery(mastery);
        _nextCard();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color, width: 1),
      ),
      child: Text(label),
    );
  }
}

