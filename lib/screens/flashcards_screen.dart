import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../services/learning_progress_service.dart';
import '../utils/toast_utils.dart';

/// FR-8 抽認卡學習功能（整合版）
/// FR-8.1: 查看文件對應的抽認卡集合
/// FR-8.2: 卡片形式呈現，正面問題，背面答案
/// FR-8.3: 點擊觸發翻轉動畫
/// FR-8.4: 左右滑動切換卡片
/// FR-8.5: 標記為「已掌握」、「需複習」或「困難」
/// FR-8.6: 記錄每張卡片的標記狀態
/// FR-8.7: 顯示學習進度
/// FR-8.8: 顯示卡片的標籤分類
/// FR-8.9: 篩選特定標記狀態的卡片
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
  final LearningProgressService _progressService = LearningProgressService();
  
  late AnimationController _flipController;
  bool _isFlipped = false;
  int _currentIndex = 0;
  List<Flashcard> _flashcards = [];
  List<Flashcard> _allFlashcards = [];
  
  // FR-8.9: 篩選狀態
  String _filterStatus = 'all';
  
  // FR-8.4: 滑動控制
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
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

  Future<void> _updateCardStatus(String status) async {
    if (_flashcards.isEmpty || _currentIndex >= _flashcards.length) return;
    
    final card = _flashcards[_currentIndex];
    try {
      await _flashcardService.updateCardStatus(widget.projectId, card.id, status);
      
      setState(() {
        _flashcards[_currentIndex] = card.copyWith(status: status);
        final allIndex = _allFlashcards.indexWhere((c) => c.id == card.id);
        if (allIndex != -1) {
          _allFlashcards[allIndex] = _allFlashcards[allIndex].copyWith(status: status);
        }
      });
      
      _updateLearningProgress();
      
      if (!mounted) return;
      
      String statusLabel;
      switch (status) {
        case 'mastered':
          statusLabel = '已掌握';
          break;
        case 'review':
          statusLabel = '需複習';
          break;
        case 'difficult':
          statusLabel = '困難';
          break;
        default:
          statusLabel = '未學習';
      }
      
      ToastUtils.success(context, '已標記為「$statusLabel」');
      
      if (_currentIndex < _flashcards.length - 1) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _nextCard();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, '標記失敗: $e');
    }
  }

  Future<void> _updateLearningProgress() async {
    final stats = _getProgressStats();
    try {
      await _progressService.updateFlashcardStats(
        projectId: widget.projectId,
        totalFlashcards: stats['total']!,
        masteredFlashcards: stats['mastered']!,
        reviewFlashcards: stats['review']!,
        difficultFlashcards: stats['difficult']!,
        unlearnedFlashcards: stats['unlearned']!,
      );
    } catch (e) {
      debugPrint('更新學習進度失敗: $e');
    }
  }

  Map<String, int> _getProgressStats() {
    final cards = _allFlashcards;
    final mastered = cards.where((c) => c.status == 'mastered').length;
    final review = cards.where((c) => c.status == 'review').length;
    final difficult = cards.where((c) => c.status == 'difficult').length;
    final unlearned = cards.where((c) => c.status == 'unlearned').length;
    final favorites = cards.where((c) => c.isFavorite).length;
    
    return {
      'total': cards.length,
      'learned': mastered + review + difficult,
      'mastered': mastered,
      'review': review,
      'difficult': difficult,
      'unlearned': unlearned,
      'favorites': favorites,
    };
  }

  List<Flashcard> _getFilteredCards() {
    if (_filterStatus == 'all') return _allFlashcards;
    if (_filterStatus == 'favorites') return _allFlashcards.where((c) => c.isFavorite).toList();
    return _allFlashcards.where((c) => c.status == _filterStatus).toList();
  }

  Future<void> _showGenerateConfirmation() async {
    String selectedLanguage = 'zh';
    
    final confirmed = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('生成抽認卡', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '將使用 AI 根據您上傳的文件內容生成 10 張抽認卡。\n\n這可能需要一些時間，確定要繼續嗎？',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text('生成語言：', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('開始生成'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null) {
      await _generateFlashcards(confirmed);
    }
  }

  Future<void> _generateFlashcards(String language) async {
    if (!mounted) return;
    
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
                const Text('AI 正在生成抽認卡...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('正在分析文件內容並生成學習卡片 ($languageText)\n請稍候片刻', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final flashcards = await _flashcardService.generateFlashcards(projectId: widget.projectId, count: 10, language: language);
      if (!mounted) return;
      Navigator.of(context).pop();
      
      setState(() {
        _currentIndex = 0;
        _isFlipped = false;
      });
      
      ToastUtils.success(context, '✓ 成功生成 ${flashcards.length} 個抽認卡');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ToastUtils.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteFlashcard(String flashcardId) async {
    try {
      await _flashcardService.deleteFlashcard(widget.projectId, flashcardId);
      if (!mounted) return;
      ToastUtils.success(context, '✓ 抽認卡已刪除');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, '✗ 刪除失敗: $e');
    }
  }

  Future<void> _deleteAllFlashcards(List<Flashcard> flashcards) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('刪除所有抽認卡', style: TextStyle(color: Colors.white)),
        content: Text('確定要刪除所有 ${flashcards.length} 張抽認卡嗎？此操作無法復原。', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消', style: TextStyle(color: Colors.white54))),
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
        for (var flashcard in flashcards) {
          await _flashcardService.deleteFlashcard(widget.projectId, flashcard.id);
        }
        setState(() => _currentIndex = 0);
        if (!mounted) return;
        ToastUtils.success(context, '✓ 已刪除 ${flashcards.length} 張抽認卡');
      } catch (e) {
        if (!mounted) return;
        ToastUtils.error(context, '✗ 刪除失敗: $e');
      }
    }
  }

  Future<void> _toggleFavorite(Flashcard card) async {
    final newFavoriteStatus = !card.isFavorite;
    
    setState(() {
      final index = _flashcards.indexWhere((c) => c.id == card.id);
      if (index != -1) _flashcards[index] = card.copyWith(isFavorite: newFavoriteStatus);
      final allIndex = _allFlashcards.indexWhere((c) => c.id == card.id);
      if (allIndex != -1) _allFlashcards[allIndex] = _allFlashcards[allIndex].copyWith(isFavorite: newFavoriteStatus);
    });
    
    try {
      await _flashcardService.toggleFavorite(widget.projectId, card.id, newFavoriteStatus);
      if (!mounted) return;
      ToastUtils.success(context, newFavoriteStatus ? '已加入收藏' : '已取消收藏');
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _flashcards.indexWhere((c) => c.id == card.id);
          if (index != -1) _flashcards[index] = card.copyWith(isFavorite: !newFavoriteStatus);
        });
      }
      if (!mounted) return;
      ToastUtils.error(context, '操作失敗: $e');
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
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: _filterStatus != 'all' ? Colors.orange : Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
                _currentIndex = 0;
                _isFlipped = false;
                _flipController.reset();
                _flashcards = _getFilteredCards();
              });
            },
            itemBuilder: (context) {
              final stats = _getProgressStats();
              return [
                _buildFilterMenuItem('all', '全部', Icons.all_inclusive, Colors.blue, stats['total']!),
                _buildFilterMenuItem('unlearned', '未學習', Icons.help_outline, Colors.grey, stats['unlearned']!),
                _buildFilterMenuItem('mastered', '已掌握', Icons.check_circle, Colors.green, stats['mastered']!),
                _buildFilterMenuItem('review', '需複習', Icons.refresh, Colors.orange, stats['review']!),
                _buildFilterMenuItem('difficult', '困難', Icons.warning, Colors.red, stats['difficult']!),
                const PopupMenuDivider(),
                _buildFilterMenuItem('favorites', '收藏', Icons.star, Colors.amber, stats['favorites']!),
              ];
            },
          ),
          StreamBuilder<List<Flashcard>>(
            stream: _flashcardService.watchFlashcards(widget.projectId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: () => _deleteAllFlashcards(snapshot.data!),
                tooltip: '刪除所有抽認卡',
              );
            },
          ),
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _showGenerateConfirmation, tooltip: '生成抽認卡'),
        ],
      ),
      body: StreamBuilder<List<Flashcard>>(
        stream: _flashcardService.watchFlashcards(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          _allFlashcards = snapshot.data!;
          final filteredCards = _getFilteredCards();
          
          if (_flashcards.isEmpty || _flashcards.length != filteredCards.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _flashcards = filteredCards;
                  if (_currentIndex >= _flashcards.length) {
                    _currentIndex = _flashcards.isNotEmpty ? _flashcards.length - 1 : 0;
                  }
                });
              }
            });
          }
              
          if (_allFlashcards.isEmpty) return _buildEmptyState();
          if (filteredCards.isEmpty) return _buildFilterEmptyState();
          if (_currentIndex >= filteredCards.length) _currentIndex = 0;
          if (_flashcards.isEmpty) _flashcards = filteredCards;

          final currentCard = _flashcards[_currentIndex];

          return Column(
            children: [
              _buildProgressHeader(),
              Expanded(child: _buildCardArea(currentCard)),
              _buildStatusButtons(),
              _buildNavigationButtons(),
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label, IconData icon, Color color, int count) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          if (_filterStatus == value) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check, color: Colors.white, size: 16)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('還沒有抽認卡', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showGenerateConfirmation,
            icon: const Icon(Icons.add),
            label: const Text('生成抽認卡'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    String message;
    IconData icon;
    
    switch (_filterStatus) {
      case 'mastered': message = '還沒有已掌握的卡片'; icon = Icons.check_circle_outline; break;
      case 'review': message = '沒有需要複習的卡片'; icon = Icons.refresh; break;
      case 'difficult': message = '沒有困難的卡片'; icon = Icons.warning_outlined; break;
      case 'unlearned': message = '所有卡片都已學習過'; icon = Icons.school; break;
      case 'favorites': message = '還沒有收藏的抽認卡'; icon = Icons.star_border; break;
      default: message = '沒有抽認卡'; icon = Icons.quiz_outlined;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => setState(() { _filterStatus = 'all'; _currentIndex = 0; _flashcards = _getFilteredCards(); }),
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('顯示全部'),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final stats = _getProgressStats();
    final progress = stats['total']! > 0 ? stats['learned']! / stats['total']! : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('第 ${_currentIndex + 1} 張 / 共 ${_flashcards.length} 張', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              if (_flashcards.isNotEmpty) _buildCurrentCardStatusLabel(),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation<Color>(Colors.green), minHeight: 6),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('已掌握', stats['mastered']!, Colors.green),
              _buildStatItem('需複習', stats['review']!, Colors.orange),
              _buildStatItem('困難', stats['difficult']!, Colors.red),
              _buildStatItem('未學習', stats['unlearned']!, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCardStatusLabel() {
    final card = _flashcards[_currentIndex];
    final color = Color(Flashcard.getStatusColor(card.status));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(card.statusLabel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }

  Widget _buildCardArea(Flashcard currentCard) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => setState(() => _dragOffset += details.delta.dx),
      onHorizontalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dx;
        if (_dragOffset > 100 || velocity > 500) {
          _previousCard();
        } else if (_dragOffset < -100 || velocity < -500) {
          _nextCard();
        }
        setState(() => _dragOffset = 0);
      },
      onTap: _flipCard,
      child: Center(
        child: AnimatedBuilder(
          animation: _flipController,
          builder: (context, child) {
            final angle = _flipController.value * math.pi;
            final isFront = angle < math.pi / 2;
            
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle)
                ..storage[12] = _dragOffset * 0.3,
              child: isFront
                  ? _buildCardFront(currentCard)
                  : Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: _buildCardBack(currentCard)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(Flashcard card) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // 可點擊區域（翻轉）- 藍色主題
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight, 
                    colors: [Colors.blue.withValues(alpha: 0.35), Colors.blue.withValues(alpha: 0.15)],
                  ),
                ),
                child: Stack(
                  children: [
                    // 問題標籤
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.help_outline, color: Colors.white70, size: 14), SizedBox(width: 4), Text('問題', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                      ),
                    ),
                    // 問題內容
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            card.question, 
                            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w500, height: 1.5), 
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    // 點擊提示
                    Positioned(
                      bottom: 8, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text('點擊翻轉查看答案', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 分隔線
            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            // 不可點擊區域（按鈕區）- 深色主題
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 標籤
                  if (card.tags.isNotEmpty)
                    Expanded(child: _buildTagsDisplay(card.tags))
                  else
                    const Expanded(child: SizedBox()),
                  // 收藏按鈕
                  GestureDetector(
                    onTap: () => _toggleFavorite(card),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: card.isFavorite ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        card.isFavorite ? Icons.star : Icons.star_border, 
                        color: card.isFavorite ? Colors.amber : Colors.white54, 
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(Flashcard card) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // 可點擊區域（翻轉）- 綠色主題
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight, 
                    colors: [Colors.green.withValues(alpha: 0.35), Colors.green.withValues(alpha: 0.15)],
                  ),
                ),
                child: Stack(
                  children: [
                    // 答案標籤
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lightbulb_outline, color: Colors.white70, size: 14), SizedBox(width: 4), Text('答案', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                      ),
                    ),
                    // 答案內容
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            card.answer, 
                            style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.6), 
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    // 點擊提示
                    Positioned(
                      bottom: 8, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text('點擊翻回問題', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 分隔線
            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            // 不可點擊區域（按鈕區）- 深色主題
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 難度標籤
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(card.difficulty).withValues(alpha: 0.2), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getDifficultyColor(card.difficulty).withValues(alpha: 0.5)),
                    ),
                    child: Text(card.difficultyLabel, style: TextStyle(color: _getDifficultyColor(card.difficulty), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  // 刪除按鈕
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('刪除抽認卡', style: TextStyle(color: Colors.white)),
                          content: const Text('確定要刪除這張抽認卡嗎？', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消', style: TextStyle(color: Colors.white54))),
                            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('刪除')),
                          ],
                        ),
                      );
                      if (confirmed == true) await _deleteFlashcard(card.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete_outline, size: 20, color: Colors.red.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsDisplay(List<String> tags) {
    return Wrap(
      spacing: 4, runSpacing: 4,
      children: tags.take(2).map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Text('#$tag', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
      )).toList(),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusButtons() {
    if (!_isFlipped || _flashcards.isEmpty) return const SizedBox(height: 8);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text('這張卡片你掌握了嗎？', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatusButton('困難', 'difficult', Colors.red, Icons.warning)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusButton('需複習', 'review', Colors.orange, Icons.refresh)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusButton('已掌握', 'mastered', Colors.green, Icons.check_circle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, Color color, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => _updateCardStatus(status),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentIndex > 0 ? _previousCard : null,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('上一張'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: _currentIndex > 0 ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _flipCard,
            icon: Icon(_isFlipped ? Icons.refresh : Icons.flip, size: 18),
            label: Text(_isFlipped ? '看問題' : '看答案'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentIndex < _flashcards.length - 1 ? _nextCard : null,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('下一張'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }
}

