import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../models/question.dart';
import '../models/note.dart';
import '../services/content_search_service.dart';
import '../utils/toast_utils.dart';
import 'flashcards_screen.dart';
import 'quiz_screen.dart';
import 'notes_screen.dart';

/// FR-10 內容搜尋與篩選畫面
class ContentSearchScreen extends StatefulWidget {
  final String projectId;
  final String? fileId; // 可選：限定特定文件
  final String? initialQuery;

  const ContentSearchScreen({
    super.key,
    required this.projectId,
    this.fileId,
    this.initialQuery,
  });

  @override
  State<ContentSearchScreen> createState() => _ContentSearchScreenState();
}

class _ContentSearchScreenState extends State<ContentSearchScreen>
    with SingleTickerProviderStateMixin {
  final ContentSearchService _searchService = ContentSearchService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // 篩選狀態
  String _selectedContentType =
      'all'; // 'all' | 'flashcards' | 'questions' | 'notes'
  String? _selectedDifficulty; // null | 'easy' | 'medium' | 'hard'
  String? _selectedTag;
  List<String> _availableTags = [];

  // 搜尋結果
  SearchResults? _searchResults;
  ContentStats? _contentStats;
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedContentType = 'all';
            break;
          case 1:
            _selectedContentType = 'flashcards';
            break;
          case 2:
            _selectedContentType = 'questions';
            break;
          case 3:
            _selectedContentType = 'notes';
            break;
        }
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // 載入內容統計
      if (widget.fileId != null) {
        _contentStats = await _searchService.getFileContentStats(
          widget.projectId,
          widget.fileId!,
        );
      } else {
        _contentStats = await _searchService.getContentStats(widget.projectId);
      }

      // 載入可用標籤
      _availableTags = await _searchService.getAllTags(widget.projectId);

      // 如果有初始查詢，執行搜尋
      if (_searchController.text.isNotEmpty) {
        await _performSearch();
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.error(context, '載入失敗: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }

    setState(() => _isSearching = true);

    try {
      _searchResults = await _searchService.searchContent(
        widget.projectId,
        query,
        searchFlashcards:
            _selectedContentType == 'all' ||
            _selectedContentType == 'flashcards',
        searchQuestions:
            _selectedContentType == 'all' ||
            _selectedContentType == 'questions',
        searchNotes:
            _selectedContentType == 'all' || _selectedContentType == 'notes',
      );
    } catch (e) {
      if (mounted) {
        ToastUtils.error(context, '搜尋失敗: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('內容搜尋', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // 搜尋框
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '搜尋抽認卡、題目、筆記...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = null);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (value) {
                    setState(() {});
                    if (value.length >= 2) {
                      _performSearch();
                    }
                  },
                ),
              ),
              // 類型標籤
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(
                    text:
                        '全部${_contentStats != null ? ' (${_contentStats!.totalCount})' : ''}',
                  ),
                  Tab(
                    text:
                        '抽認卡${_contentStats != null ? ' (${_contentStats!.flashcardsCount})' : ''}',
                  ),
                  Tab(
                    text:
                        '題目${_contentStats != null ? ' (${_contentStats!.questionsCount})' : ''}',
                  ),
                  Tab(
                    text:
                        '筆記${_contentStats != null ? ' (${_contentStats!.notesCount})' : ''}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // FR-10.3 & FR-10.4: 篩選條件
                _buildFilterBar(),
                // 搜尋結果或內容瀏覽
                Expanded(
                  child: _searchResults != null
                      ? _buildSearchResults()
                      : _buildContentBrowser(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // FR-10.3: 難度篩選
            _buildFilterDropdown(
              label: '難度',
              value: _selectedDifficulty,
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                const DropdownMenuItem(value: 'easy', child: Text('簡單')),
                const DropdownMenuItem(value: 'medium', child: Text('中等')),
                const DropdownMenuItem(value: 'hard', child: Text('困難')),
              ],
              onChanged: (value) {
                setState(() => _selectedDifficulty = value);
              },
            ),
            const SizedBox(width: 12),
            // FR-10.4: 標籤篩選
            if (_availableTags.isNotEmpty) ...[
              _buildFilterDropdown(
                label: '標籤',
                value: _selectedTag,
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部')),
                  ..._availableTags
                      .take(20)
                      .map(
                        (tag) => DropdownMenuItem(
                          value: tag,
                          child: Text(tag, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ],
                onChanged: (value) {
                  setState(() => _selectedTag = value);
                },
              ),
            ],
            // 清除篩選按鈕
            if (_selectedDifficulty != null || _selectedTag != null) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDifficulty = null;
                    _selectedTag = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('清除篩選'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value != null
              ? Colors.blue.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_searchResults == null || _searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '找不到相關內容',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // 全部
        _buildAllResultsList(),
        // 抽認卡
        _buildFlashcardsList(_searchResults!.flashcards),
        // 題目
        _buildQuestionsList(_searchResults!.questions),
        // 筆記
        _buildNotesList(_searchResults!.notes),
      ],
    );
  }

  Widget _buildContentBrowser() {
    return TabBarView(
      controller: _tabController,
      children: [
        // 全部 - 顯示統計概覽
        _buildStatsOverview(),
        // 抽認卡
        _buildFlashcardsStream(),
        // 題目
        _buildQuestionsStream(),
        // 筆記
        _buildNotesStream(),
      ],
    );
  }

  Widget _buildAllResultsList() {
    final results = _searchResults!;
    final items = <Widget>[];

    // 組合所有結果
    if (results.flashcards.isNotEmpty) {
      items.add(_buildSectionHeader('抽認卡', results.flashcards.length));
      items.addAll(results.flashcards.map((f) => _buildFlashcardItem(f)));
    }
    if (results.questions.isNotEmpty) {
      items.add(_buildSectionHeader('題目', results.questions.length));
      items.addAll(results.questions.map((q) => _buildQuestionItem(q)));
    }
    if (results.notes.isNotEmpty) {
      items.add(_buildSectionHeader('筆記', results.notes.length));
      items.addAll(results.notes.map((n) => _buildNoteItem(n)));
    }

    return ListView(padding: const EdgeInsets.all(16), children: items);
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_contentStats == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // FR-10.2: 內容類型統計卡片
        _buildStatsCard(
          '抽認卡',
          _contentStats!.flashcardsCount,
          Icons.style,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildStatsCard(
          '題目',
          _contentStats!.questionsCount,
          Icons.quiz,
          Colors.orange,
          subtitle:
              '單選 ${_contentStats!.mcqSingleCount} / '
              '多選 ${_contentStats!.mcqMultipleCount} / '
              '問答 ${_contentStats!.openEndedCount}',
        ),
        const SizedBox(height: 12),
        _buildStatsCard(
          '筆記',
          _contentStats!.notesCount,
          Icons.note,
          Colors.green,
        ),
        const SizedBox(height: 24),
        // 標籤雲
        if (_availableTags.isNotEmpty) ...[
          const Text(
            '熱門標籤',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.take(15).map((tag) {
              return ActionChip(
                label: Text(tag),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: Colors.white),
                onPressed: () {
                  _searchController.text = tag;
                  _performSearch();
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard(
    String title,
    int count,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Stream builders for browsing content with filters
  Widget _buildFlashcardsStream() {
    return StreamBuilder<List<Flashcard>>(
      stream: _searchService.watchFlashcardsByDifficulty(
        widget.projectId,
        difficulty: _selectedDifficulty,
        fileId: widget.fileId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        var flashcards = snapshot.data!;

        // FR-10.4: 標籤篩選
        if (_selectedTag != null) {
          flashcards = flashcards
              .where((f) => f.tags.contains(_selectedTag))
              .toList();
        }

        return _buildFlashcardsList(flashcards);
      },
    );
  }

  Widget _buildQuestionsStream() {
    return StreamBuilder<List<Question>>(
      stream: _searchService.watchQuestionsByDifficulty(
        widget.projectId,
        difficulty: _selectedDifficulty,
        fileId: widget.fileId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return _buildQuestionsList(snapshot.data!);
      },
    );
  }

  Widget _buildNotesStream() {
    // 如果有選擇標籤，使用標籤篩選
    if (_selectedTag != null) {
      return StreamBuilder<List<Note>>(
        stream: _searchService.watchNotesByKeyword(widget.projectId, _selectedTag!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildEmptyState('載入失敗: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return _buildNotesList(snapshot.data!);
        },
      );
    }
    
    // 沒有選擇標籤，載入所有筆記
    return FutureBuilder<SearchResults>(
      future: _searchService.searchContent(
        widget.projectId,
        '',
        searchFlashcards: false,
        searchQuestions: false,
        searchNotes: true,
      ),
      builder: (context, futureSnapshot) {
        if (futureSnapshot.hasError) {
          return _buildEmptyState('載入失敗: ${futureSnapshot.error}');
        }
        if (!futureSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return _buildNotesList(futureSnapshot.data!.notes);
      },
    );
  }

  Widget _buildFlashcardsList(List<Flashcard> flashcards) {
    if (flashcards.isEmpty) {
      return _buildEmptyState('沒有抽認卡');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: flashcards.length,
      itemBuilder: (context, index) => _buildFlashcardItem(flashcards[index]),
    );
  }

  Widget _buildQuestionsList(List<Question> questions) {
    if (questions.isEmpty) {
      return _buildEmptyState('沒有題目');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) => _buildQuestionItem(questions[index]),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState('沒有筆記');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) => _buildNoteItem(notes[index]),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardItem(Flashcard flashcard) {
    return GestureDetector(
      onTap: () => _navigateToFlashcard(flashcard),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      flashcard.difficulty,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    flashcard.difficultyLabel,
                    style: TextStyle(
                      color: _getDifficultyColor(flashcard.difficulty),
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.style,
                  size: 16,
                  color: Colors.blue.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              flashcard.question,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (flashcard.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: flashcard.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(Question question) {
    Color typeColor;
    String typeLabel;
    if (question.isMcqSingle) {
      typeColor = Colors.blue;
      typeLabel = '單選';
    } else if (question.isMcqMultiple) {
      typeColor = Colors.orange;
      typeLabel = '多選';
    } else {
      typeColor = Colors.purple;
      typeLabel = '問答';
    }

    return GestureDetector(
      onTap: () => _navigateToQuestion(question),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: typeColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(color: typeColor, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      question.difficulty,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.difficultyLabel,
                    style: TextStyle(
                      color: _getDifficultyColor(question.difficulty),
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.quiz,
                  size: 16,
                  color: typeColor.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(Note note) {
    return GestureDetector(
      onTap: () => _navigateToNote(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.note,
                  size: 16,
                  color: Colors.green.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.detailedExplanation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.keywords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: note.keywords.take(5).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      keyword,
                      style: const TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== 導航方法 ====================

  /// 導航到抽認卡學習畫面（跳到指定的抽認卡）
  void _navigateToFlashcard(Flashcard flashcard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardsScreen(
          projectId: widget.projectId,
          initialFlashcardId: flashcard.id,
        ),
      ),
    );
  }

  /// 導航到題目測驗畫面（只顯示選中的題目）
  void _navigateToQuestion(Question question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          projectId: widget.projectId,
          questions: [question], // 只傳入這一題
        ),
      ),
    );
  }

  /// 導航到筆記畫面（跳到指定的筆記）
  void _navigateToNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotesScreen(
          projectId: widget.projectId,
          initialNoteId: note.id,
        ),
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
}
