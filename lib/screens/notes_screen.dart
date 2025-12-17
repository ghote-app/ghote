import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import '../services/note_service.dart';
import '../utils/toast_utils.dart';

class NotesScreen extends StatefulWidget {
  final String projectId;

  const NotesScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];
  bool _isLoading = true;
  String _filterImportance = 'all'; // 'all' | 'high' | 'medium' | 'low'
  
  // FR-5.5: 追蹤每個筆記各段落的展開/收合狀態
  final Map<String, Set<String>> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    _noteService.watchNotes(widget.projectId).listen((notes) {
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
          // 初始化展開狀態（預設全部展開）
          for (final note in notes) {
            _expandedSections[note.id] ??= {'concepts', 'explanation', 'keywords'};
          }
        });
      }
    });
  }
  
  // FR-5.5: 切換段落展開/收合
  void _toggleSection(String noteId, String section) {
    setState(() {
      // 如果尚未初始化，預設全部展開
      _expandedSections[noteId] ??= {'concepts', 'explanation', 'keywords'};
      if (_expandedSections[noteId]!.contains(section)) {
        _expandedSections[noteId]!.remove(section);
      } else {
        _expandedSections[noteId]!.add(section);
      }
    });
  }
  
  bool _isSectionExpanded(String noteId, String section) {
    return _expandedSections[noteId]?.contains(section) ?? true;
  }
  
  // FR-5.6: 複製筆記內容
  void _copyNoteContent(Note note) {
    final buffer = StringBuffer();
    buffer.writeln('【${note.title}】');
    buffer.writeln('重要性：${note.importanceLabel}');
    buffer.writeln();
    buffer.writeln('📌 主要概念：');
    for (final concept in note.mainConcepts) {
      buffer.writeln('• $concept');
    }
    buffer.writeln();
    buffer.writeln('📝 詳細說明：');
    buffer.writeln(note.detailedExplanation);
    buffer.writeln();
    buffer.writeln('🏷️ 關鍵字：${note.keywords.map((k) => '#$k').join(' ')}');
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ToastUtils.success(context, '已複製筆記內容');
  }

  List<Note> get _filteredNotes {
    if (_filterImportance == 'all') return _notes;
    return _notes.where((n) => n.importance == _filterImportance).toList();
  }

  Future<void> _showGenerateConfirmation() async {
    String selectedLanguage = 'zh';

    final confirmed = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '生成重點筆記',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '將使用 AI 根據您上傳的文件內容生成 5 份重點筆記。\n\n這可能需要一些時間，確定要繼續嗎？',
                style: TextStyle(color: Colors.white70),
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
                      onChanged: (value) =>
                          setState(() => selectedLanguage = value!),
                      title: const Text('中文',
                          style: TextStyle(color: Colors.white)),
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'en',
                      groupValue: selectedLanguage,
                      onChanged: (value) =>
                          setState(() => selectedLanguage = value!),
                      title: const Text('English',
                          style: TextStyle(color: Colors.white)),
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
              child:
                  const Text('取消', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedLanguage),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('確定生成'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null) {
      await _generateNotes(confirmed);
    }
  }

  Future<void> _generateNotes(String language) async {
    // 顯示生成中對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'AI 正在分析文件並生成重點筆記...',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 8),
            Text(
              '這可能需要 10-30 秒',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      await _noteService.generateNotes(
        projectId: widget.projectId,
        count: 5,
        language: language,
      );
      if (!mounted) return;
      Navigator.of(context).pop();

      ToastUtils.success(
        context,
        '✓ 成功生成重點筆記',
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

  Color _getImportanceColor(String importance) {
    switch (importance) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('重點筆記'),
        actions: [
          // 重要性過濾
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterImportance = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    if (_filterImportance == 'all')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    const Text('全部'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'high',
                child: Row(
                  children: [
                    if (_filterImportance == 'high')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('高重要性'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'medium',
                child: Row(
                  children: [
                    if (_filterImportance == 'medium')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('中重要性'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'low',
                child: Row(
                  children: [
                    if (_filterImportance == 'low')
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('低重要性'),
                  ],
                ),
              ),
            ],
          ),
          // 生成按鈕
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _showGenerateConfirmation,
            tooltip: '生成重點筆記',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notes,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _filterImportance == 'all' ? '尚無重點筆記' : '沒有符合條件的筆記',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊右上角的 ✨ 按鈕來生成',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showGenerateConfirmation,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('生成重點筆記'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showNoteDetail(note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題行
              Row(
                children: [
                  // 重要性標記
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getImportanceColor(note.importance),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 收藏按鈕
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.star : Icons.star_border,
                      color: note.isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(note),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 主要概念
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.mainConcepts.take(3).map((concept) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      concept,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // 詳細說明預覽
              Text(
                note.detailedExplanation,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 關鍵字
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: note.keywords.map((keyword) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$keyword',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDetail(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // 拖曳指示器
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 標題和重要性
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getImportanceColor(note.importance)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${note.importanceLabel}重要',
                                  style: TextStyle(
                                    color: _getImportanceColor(note.importance),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // FR-5.6: 複製全部按鈕
                              IconButton(
                                icon: const Icon(Icons.copy_all, color: Colors.white70),
                                onPressed: () => _copyNoteContent(note),
                                tooltip: '複製全部內容',
                              ),
                              IconButton(
                                icon: Icon(
                                  note.isFavorite ? Icons.star : Icons.star_border,
                                  color:
                                      note.isFavorite ? Colors.amber : Colors.grey,
                                ),
                                onPressed: () {
                                  _toggleFavorite(note);
                                  Navigator.pop(context);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _confirmDelete(note),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 標題
                        Text(
                          note.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // FR-5.5: 可展開/收合的主要概念
                        _buildExpandableSection(
                          noteId: note.id,
                          sectionKey: 'concepts',
                          title: '📌 主要概念',
                          setModalState: setModalState,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: note.mainConcepts.map((concept) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 16)),
                                  Expanded(
                                    child: Text(
                                      concept,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // FR-5.5: 可展開/收合的詳細說明
                        _buildExpandableSection(
                          noteId: note.id,
                          sectionKey: 'explanation',
                          title: '📝 詳細說明',
                          setModalState: setModalState,
                          content: Text(
                            note.detailedExplanation,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // FR-5.5: 可展開/收合的關鍵字
                        _buildExpandableSection(
                          noteId: note.id,
                          sectionKey: 'keywords',
                          title: '🏷️ 關鍵字',
                          setModalState: setModalState,
                          content: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: note.keywords.map((keyword) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '#$keyword',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // FR-5.5: 可展開/收合的段落組件
  Widget _buildExpandableSection({
    required String noteId,
    required String sectionKey,
    required String title,
    required Widget content,
    required StateSetter setModalState,
  }) {
    final isExpanded = _isSectionExpanded(noteId, sectionKey);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            _toggleSection(noteId, sectionKey);
            setModalState(() {}); // 更新 modal 狀態
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: content,
          ),
          crossFadeState: isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(Note note) async {
    try {
      await _noteService.toggleFavorite(
        widget.projectId,
        note.id,
        !note.isFavorite,
      );
    } catch (e) {
      if (mounted) {
        ToastUtils.error(context, '更新失敗');
      }
    }
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('刪除筆記', style: TextStyle(color: Colors.white)),
        content: Text(
          '確定要刪除「${note.title}」嗎？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _noteService.deleteNote(widget.projectId, note.id);
        if (mounted) {
          Navigator.of(context).pop(); // 關閉詳情
          ToastUtils.success(context, '已刪除筆記');
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.error(context, '刪除失敗');
        }
      }
    }
  }
}
