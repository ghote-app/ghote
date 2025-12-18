import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

import '../models/file_model.dart';
import '../models/learning_progress.dart';
import '../services/project_service.dart';
import '../services/subscription_service.dart';
import '../services/storage_service.dart';
import '../services/document_extraction_service.dart';
import '../services/gemini_service.dart';
import '../services/flashcard_service.dart';
import '../services/question_service.dart';
import '../services/note_service.dart';
import '../services/learning_progress_service.dart';
import '../utils/toast_utils.dart';
import 'chat_screen.dart';
import 'flashcards_screen.dart';
import 'questions_screen.dart';
import 'notes_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key, required this.projectId, required this.title});

  final String projectId;
  final String title;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  String _selectedCategory = 'all'; // 'all', 'document', 'image', 'video', 'audio', 'other'
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  String _currentTitle = '';
  
  // FR-3.3: 上傳進度回調
  void Function(int count, String fileName)? _uploadProgressCallback;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    // 清理 callback 避免記憶體洩漏
    _uploadProgressCallback = null;
    super.dispose();
  }

  // 根據副檔名判斷檔案分類
  String _getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    
    // 文件類型
    if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'].contains(ext)) {
      return 'document';
    }
    
    // 圖片類型
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp', 'ico', 'tiff', 'heic'].contains(ext)) {
      return 'image';
    }
    
    // 影片類型
    if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm', 'm4v', '3gp'].contains(ext)) {
      return 'video';
    }
    
    // 音訊類型
    if (['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'].contains(ext)) {
      return 'audio';
    }
    
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    final projectService = ProjectService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: GestureDetector(
          onTap: _editProjectName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _currentTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.edit_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            tooltip: 'AI 智能命名',
            onPressed: _aiGenerateName,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
            tooltip: '上傳檔案',
            onPressed: _uploadFiles,
          ),
        ],
      ),
      body: StreamBuilder<List<FileModel>>(
        stream: projectService.watchFiles(widget.projectId),
        builder: (context, snapshot) {
          // 保留上次的數據，避免閃爍
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  Text(
                    '載入錯誤',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final files = snapshot.data ?? <FileModel>[];
          
          // 根據分類篩選檔案
          final filteredFiles = _selectedCategory == 'all'
              ? files
              : files.where((f) => f.category == _selectedCategory).toList();
          
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 20),
                  Text(
                    '尚無檔案',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '點擊右上角 + 開始上傳檔案',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 檔案統計區域
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildStatsCard(files),
                  ),
                ),
              ),
              
              // AI 功能操作欄
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAIActionsBar(),
                  ),
                ),
              ),
              
              // FR-9.4: 學習進度區塊
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildLearningProgressCard(),
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              
              // 分類篩選器 - 使用 SliverPersistentHeader 固定
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryFilterDelegate(
                  child: RepaintBoundary(
                    child: Container(
                      color: Colors.black,
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                      child: _buildCategoryFilter(files),
                    ),
                  ),
                ),
              ),
              
              // 檔案列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final file = filteredFiles[index];
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          key: ValueKey(file.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFileCard(context, file),
                        ),
                      );
                    },
                    childCount: filteredFiles.length,
                    findChildIndexCallback: (Key key) {
                      final valueKey = key as ValueKey<String>;
                      return filteredFiles.indexWhere((file) => file.id == valueKey.value);
                    },
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }

  // 檔案上傳功能
  Future<void> _uploadFiles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ToastUtils.info(context, '請先登入');
        return;
      }

      // 選擇檔案
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'txt', 'doc', 'docx', 'mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac', 'wma'],
      );

      if (result == null || result.files.isEmpty) return;

      // 檢查單檔大小限制 (10MB)
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      for (final f in result.files) {
        if (f.size > maxFileSize) {
          if (!mounted) return;
          ToastUtils.warning(context, '檔案大小超過 10MB 上限，已取消上傳。');
          return;
        }
      }

      // 獲取訂閱和當前檔案數量（添加重試機制）
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          final subscription = await SubscriptionService().getUserSubscription(user.uid);
          final currentFileCount = await ProjectService().getProjectFileCount(widget.projectId);

          // 檢查檔案數量限制 (免費/Plus: 10個)
          if (subscription.isFree || subscription.isPlus) {
            if (currentFileCount + result.files.length > 10) {
              if (!mounted) return;
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text('File Limit Reached', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    '免費/Plus 方案每個專案最多 10 個文件。請升級到 Ghote Pro 享受無限文件上傳。',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }
          }
          break; // 成功，跳出重試循環
        } catch (e) {
          retryCount++;
          if (retryCount < maxRetries) {
            // 等待後重試
            await Future.delayed(Duration(seconds: retryCount));
          } else {
            // 達到最大重試次數
            if (!mounted) return;
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  '網路連線問題',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  '無法連接到伺服器，請檢查您的網路連線。\n\n錯誤詳情：${e.toString().contains('UNAVAILABLE') ? '服務暫時無法使用' : e.toString()}',
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
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
            
            if (shouldContinue == true) {
              // 用戶選擇重試，遞歸調用
              return _uploadFiles();
            } else {
              return; // 用戶取消
            }
          }
        }
      }

      // FR-3.3: 顯示即時上傳進度對話框
      int uploadedCount = 0;
      final totalFiles = result.files.length;
      String currentFileName = '';
      
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // 儲存 setDialogState 供後續更新（包含 mounted 檢查）
            _uploadProgressCallback = (int count, String fileName) {
              // 檢查對話框是否仍然存在
              if (dialogContext.mounted) {
                setDialogState(() {
                  uploadedCount = count;
                  currentFileName = fileName;
                });
              }
            };
            
            return PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: totalFiles > 0 ? uploadedCount / totalFiles : null,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        Text(
                          '$uploadedCount/$totalFiles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '正在上傳...',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (currentFileName.isNotEmpty)
                      Text(
                        currentFileName,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // 進度條
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalFiles > 0 ? uploadedCount / totalFiles : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // 上傳檔案到本地儲存
      final storage = const StorageService();
      final projectService = ProjectService();
      int successCount = 0;
      int failCount = 0;

      for (final f in result.files) {
        if (f.path == null) {
          failCount++;
          continue;
        }
        
        // 更新進度
        _uploadProgressCallback?.call(successCount + failCount, f.name);
        
        try {
          final file = File(f.path!);
          final now = DateTime.now();
          final fileId = '${now.microsecondsSinceEpoch}-${f.name}';
          
          // 一律儲存到本地
          final localPath = await storage.saveToLocal(file, widget.projectId);

          final meta = FileModel(
            id: fileId,
            projectId: widget.projectId,
            name: f.name,
            type: (f.extension ?? '').toLowerCase(),
            category: _getCategoryFromExtension(f.extension ?? ''),
            sizeBytes: f.size,
            storageType: 'local',
            localPath: localPath,
            cloudPath: null,
            downloadUrl: null,
            uploaderId: user.uid,
            uploadedAt: now,
            metadata: const {},
          );

          // 保存檔案元數據（添加重試機制）
          bool metadataSaved = false;
          int metadataRetry = 0;
          const maxMetadataRetries = 3;
          
          while (!metadataSaved && metadataRetry < maxMetadataRetries) {
            try {
              await projectService.addFileMetadata(widget.projectId, meta);
              metadataSaved = true;
              successCount++;
            } catch (metaError) {
              metadataRetry++;
              if (metadataRetry >= maxMetadataRetries) {
                print('保存檔案元數據 ${f.name} 失敗（已重試 $maxMetadataRetries 次）: $metaError');
                failCount++;
              } else {
                // 等待後重試
                await Future.delayed(Duration(seconds: metadataRetry));
              }
            }
          }
        } catch (e) {
          print('上傳檔案 ${f.name} 失敗: $e');
          failCount++;
        }
      }

      // 關閉進度對話框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      if (failCount > 0) {
        ToastUtils.warning(context, '✅ 成功上傳 $successCount 個檔案\n❌ $failCount 個檔案上傳失敗');
      } else {
        ToastUtils.success(context, '✅ 成功上傳 $successCount 個檔案');
        
        // FR-3.4: 上傳成功後自動開始處理（文字提取）
        if (successCount > 0) {
          _autoExtractText();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, '上傳失敗: $e');
    }
  }

  /// FR-3.4: 自動提取新上傳文件的文字
  Future<void> _autoExtractText() async {
    final projectService = ProjectService();
    final extractionService = const DocumentExtractionService();
    
    try {
      final files = await projectService.watchFiles(widget.projectId).first;
      
      // 找出尚未提取的可提取文件
      final pendingFiles = files.where((f) {
        final type = f.type.toLowerCase();
        return ['pdf', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'bmp', 'gif', 'mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'].contains(type) &&
               (f.extractionStatus == null || f.extractionStatus == 'pending');
      }).toList();
      
      if (pendingFiles.isEmpty) return;
      
      // 在背景處理，不阻擋用戶
      for (final file in pendingFiles) {
        // 在處理每個文件前，重新檢查文件是否仍然存在（可能已被用戶刪除）
        final currentFiles = await projectService.watchFiles(widget.projectId).first;
        final fileStillExists = currentFiles.any((f) => f.id == file.id);
        
        if (!fileStillExists) {
          print('文件 ${file.name} 已被刪除，跳過提取');
          continue;
        }
        
        try {
          // 更新狀態為處理中
          await extractionService.updateExtractionStatus(file.id, widget.projectId, 'processing');
          
          // 提取文字
          final text = await extractionService.extractText(file);
          
          // 再次檢查文件是否仍存在（提取過程中可能被刪除）
          final stillExists = (await projectService.watchFiles(widget.projectId).first)
              .any((f) => f.id == file.id);
          
          if (!stillExists) {
            print('文件 ${file.name} 在提取過程中被刪除');
            continue;
          }
          
          // 保存提取結果
          await extractionService.saveExtractedText(file.id, widget.projectId, text);
          
          // FR-3.6: 處理完成通知（簡化版 - 使用 Toast）
          if (mounted) {
            ToastUtils.success(context, '📄 「${file.name}」文字提取完成');
          }
        } catch (e) {
          // 檢查是否因文件被刪除導致錯誤
          final stillExists = (await projectService.watchFiles(widget.projectId).first)
              .any((f) => f.id == file.id);
          
          if (stillExists) {
            // 文件仍存在，更新狀態為失敗
            try {
              await extractionService.updateExtractionStatus(file.id, widget.projectId, 'failed');
            } catch (_) {}
          }
          print('自動提取 ${file.name} 失敗: $e');
        }
      }
    } catch (e) {
      print('自動文字提取過程出錯: $e');
    }
  }

  // 開啟檔案
  // 預覽文件
  Future<void> _previewFile(BuildContext context, FileModel file) async {
    try {
      // 檢查是否為可預覽的文件類型
      final previewableTypes = ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'txt'];
      final fileType = file.type.toLowerCase();
      
      if (!previewableTypes.contains(fileType)) {
        // 如果不是可預覽類型，直接打開文件
        await _openFile(context, file);
        return;
      }

      // 獲取文件內容
      final storage = const StorageService();
      Uint8List fileBytes;
      
      if (file.storageType == 'local' && file.localPath != null) {
        final localFile = File(file.localPath!);
        if (await localFile.exists()) {
          fileBytes = await localFile.readAsBytes();
        } else {
          throw Exception('檔案不存在');
        }
      } else if (file.storageType == 'cloud' && file.downloadUrl != null) {
        fileBytes = await storage.getFileContent(file);
      } else {
        throw Exception('無法讀取檔案');
      }

      if (!context.mounted) return;

      // 顯示預覽對話框
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 標題欄
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // 預覽內容
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: _buildFilePreview(fileType, fileBytes, file.name),
                ),
              ),
              // 操作按鈕
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      label: const Text('用其他應用開啟', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openFile(context, file);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ToastUtils.error(context, '預覽失敗: $e');
    }
  }

  // 構建文件預覽組件
  Widget _buildFilePreview(String fileType, Uint8List fileBytes, String fileName) {
    if (fileType == 'pdf') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'PDF 預覽功能需要額外的套件',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '檔案大小: ${(fileBytes.length / 1024).toStringAsFixed(2)} KB',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileType)) {
      return InteractiveViewer(
        child: Center(
          child: Image.memory(
            fileBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey, size: 64),
                    SizedBox(height: 16),
                    Text(
                      '無法顯示圖片',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else if (fileType == 'txt') {
      final text = String.fromCharCodes(fileBytes);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getFileIcon(fileType), color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              '此檔案類型不支援預覽',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openFile(BuildContext context, FileModel file) async {
    try {
      if (file.storageType == 'cloud') {
        // 雲端檔案：直接開啟下載網址
        if (file.downloadUrl != null) {
          final uri = Uri.parse(file.downloadUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('無法開啟此檔案');
          }
        } else {
          throw Exception('檔案下載網址不存在');
        }
      } else if (file.storageType == 'local') {
        // 本地檔案：使用 OpenFilex (支援 Android FileProvider)
        if (file.localPath != null) {
          final result = await OpenFilex.open(file.localPath!);
          
          // 檢查開啟結果
          if (result.type != ResultType.done) {
            if (!context.mounted) return;
            
            // 顯示錯誤訊息
            String errorMessage = '無法開啟檔案';
            if (result.type == ResultType.noAppToOpen) {
              errorMessage = '沒有適合的應用程式可以開啟此類型的檔案';
            } else if (result.type == ResultType.fileNotFound) {
              errorMessage = '檔案不存在';
            } else if (result.type == ResultType.permissionDenied) {
              errorMessage = '權限被拒絕';
            }
            
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black,
                title: const Text('無法開啟檔案', style: TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '檔案路徑：',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      file.localPath!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('關閉'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception('本地檔案路徑不存在');
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ToastUtils.error(context, '無法開啟檔案: $e');
    }
  }

  // 顯示檔案選項（刪除等）
  Future<void> _showFileOptions(BuildContext context, FileModel file) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${file.type.toUpperCase()} · ${file.formattedSize}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded, color: Colors.blue),
                title: const Text('開啟檔案', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _openFile(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                title: const Text('檔案資訊', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showFileInfo(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('刪除檔案', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteFile(context, file);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 顯示檔案詳細資訊
  Future<void> _showFileInfo(BuildContext context, FileModel file) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('檔案資訊', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('檔案名稱', file.name),
            _buildInfoRow('檔案類型', file.type.toUpperCase()),
            _buildInfoRow('檔案大小', file.formattedSize),
            _buildInfoRow('儲存位置', file.storageType == 'cloud' ? '雲端' : '本地'),
            _buildInfoRow('上傳時間', _formatDateTime(file.uploadedAt)),
            if (file.localPath != null)
              _buildInfoRow('本地路徑', file.localPath!, isPath: true),
            if (file.downloadUrl != null)
              _buildInfoRow('下載網址', file.downloadUrl!, isPath: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          isPath
              ? SelectableText(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 確認刪除檔案
  Future<void> _confirmDeleteFile(BuildContext context, FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('刪除檔案', style: TextStyle(color: Colors.white)),
        content: Text(
          '確定要刪除「${file.name}」嗎？\n\n⚠️ 此操作會同時刪除該文件生成的所有筆記、抽認卡和練習問題。',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 刪除關聯的學習內容
        final flashcardService = FlashcardService();
        final questionService = QuestionService();
        final noteService = NoteService();
        
        final deletedNotes = await noteService.deleteNotesByFileId(
          widget.projectId,
          file.id,
        );
        final deletedFlashcards = await flashcardService.deleteFlashcardsByFileId(
          widget.projectId, 
          file.id,
        );
        final deletedQuestions = await questionService.deleteQuestionsByFileId(
          widget.projectId, 
          file.id,
        );
        
        // 刪除文件元資料
        await ProjectService().deleteFileMetadata(widget.projectId, file.id);
        
        // 如果是本地檔案，嘗試刪除實體檔案
        if (file.storageType == 'local' && file.localPath != null) {
          try {
            final localFile = File(file.localPath!);
            if (await localFile.exists()) {
              await localFile.delete();
            }
          } catch (e) {
            print('刪除本地檔案失敗: $e');
          }
        }

        if (!context.mounted) return;
        
        String message = '✅ 檔案已刪除';
        if (deletedNotes > 0 || deletedFlashcards > 0 || deletedQuestions > 0) {
          message += '\n已清除 $deletedNotes 份筆記、$deletedFlashcards 張抽認卡、$deletedQuestions 道練習題';
        }
        ToastUtils.success(context, message);
      } catch (e) {
        if (!context.mounted) return;
        ToastUtils.error(context, '刪除失敗: $e');
      }
    }
  }

  Widget _buildStatsCard(List<FileModel> files) {
    final totalSize = files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    final cloudFiles = files.where((f) => f.storageType == 'cloud').length;
    final localFiles = files.where((f) => f.storageType == 'local').length;

    String formatSize(int bytes) {
      const int kb = 1024;
      const int mb = 1024 * 1024;
      if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
      if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(2)} KB';
      return '$bytes B';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              const Text(
                '專案統計',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '檔案數量',
                  '${files.length}',
                  Icons.description_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  '總大小',
                  formatSize(totalSize),
                  Icons.storage_rounded,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '雲端',
                  '$cloudFiles',
                  Icons.cloud_outlined,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  '本地',
                  '$localFiles',
                  Icons.phone_android_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 分類篩選器
  Widget _buildCategoryFilter(List<FileModel> files) {
    final categories = {
      'all': {'label': '全部', 'icon': Icons.apps_rounded, 'color': Colors.white},
      'document': {'label': '文件', 'icon': Icons.description_rounded, 'color': Colors.blue},
      'image': {'label': '圖片', 'icon': Icons.image_rounded, 'color': Colors.green},
      'video': {'label': '影片', 'icon': Icons.video_file_rounded, 'color': Colors.purple},
      'audio': {'label': '音訊', 'icon': Icons.audio_file_rounded, 'color': Colors.orange},
      'other': {'label': '其他', 'icon': Icons.insert_drive_file_rounded, 'color': Colors.grey},
    };

    // 計算每個分類的數量
    final counts = {
      'all': files.length,
      'document': files.where((f) => f.category == 'document').length,
      'image': files.where((f) => f.category == 'image').length,
      'video': files.where((f) => f.category == 'video').length,
      'audio': files.where((f) => f.category == 'audio').length,
      'other': files.where((f) => f.category == 'other').length,
    };

    return SingleChildScrollView(
      key: const PageStorageKey('category_filter_scroll'),
      controller: _categoryScrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          final count = counts[entry.key] ?? 0;
          final categoryData = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryData['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : (categoryData['color'] as Color).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${categoryData['label']}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = entry.key;
                });
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: (categoryData['color'] as Color).withValues(alpha: 0.25),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? (categoryData['color'] as Color).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, FileModel file) {
    final isCloud = file.storageType == 'cloud';
    
    // FR-3.5: 處理狀態
    Widget? statusWidget;
    if (file.extractionStatus == 'processing') {
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '處理中',
            style: TextStyle(
              color: Colors.blue.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (file.extractionStatus == 'extracted') {
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Colors.green.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            '已完成',
            style: TextStyle(
              color: Colors.green.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (file.extractionStatus == 'failed') {
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_rounded,
            size: 14,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            '處理失敗',
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _previewFile(context, file),
            onLongPress: () => _showFileOptions(context, file),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 檔案圖示
                  Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getFileColor(file.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getFileColor(file.type).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    _getFileIcon(file.type),
                    color: _getFileColor(file.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // 檔案信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // 分類標籤
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(file.category).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getCategoryColor(file.category).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _getCategoryLabel(file.category),
                              style: TextStyle(
                                color: _getCategoryColor(file.category),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            file.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            file.formattedSize,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCloud ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
                                size: 14,
                                color: isCloud ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCloud ? '雲端' : '本地',
                                style: TextStyle(
                                  color: isCloud ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          // FR-3.5: 處理狀態顯示
                          if (statusWidget != null) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                            statusWidget,
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 箭頭圖示
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      case 'mp4':
      case 'mov':
        return Icons.video_file_rounded;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'aac':
      case 'm4a':
      case 'wma':
        return Icons.audio_file_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'txt':
        return Colors.grey;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'mov':
        return Colors.pink;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'aac':
      case 'm4a':
      case 'wma':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  // 獲取分類標籤
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'document':
        return '文件';
      case 'image':
        return '圖片';
      case 'video':
        return '影片';
      case 'audio':
        return '音訊';
      default:
        return '其他';
    }
  }

  // 獲取分類顏色
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'document':
        return Colors.blue;
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.purple;
      case 'audio':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAIActionsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI 功能',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'AI 聊天',
                color: Colors.blue,
                onTap: () => _openChat(),
              ),
              _buildActionButton(
                icon: Icons.notes,
                label: '重點筆記',
                color: Colors.teal,
                onTap: () => _openNotes(),
              ),
              _buildActionButton(
                icon: Icons.quiz_outlined,
                label: '抽認卡',
                color: Colors.orange,
                onTap: () => _openFlashcards(),
              ),
              _buildActionButton(
                icon: Icons.help_outline,
                label: '練習問題',
                color: Colors.purple,
                onTap: () => _openQuestions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// FR-9.4: 學習進度卡片
  Widget _buildLearningProgressCard() {
    final progressService = LearningProgressService();
    
    return StreamBuilder<LearningProgress?>(
      stream: progressService.watchProgress(widget.projectId),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        
        // 如果沒有任何學習進度，顯示引導訊息
        if (progress == null || 
            (progress.totalFlashcards == 0 && progress.totalQuizAttempts == 0)) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '開始學習抽認卡或練習問題來追蹤進度',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withValues(alpha: 0.15),
                Colors.purple.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Colors.blue.withValues(alpha: 0.8), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '學習進度',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // 整體進度
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      progress.overallProgressPercent,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 抽認卡進度
              if (progress.totalFlashcards > 0) ...[
                _buildProgressItem(
                  icon: Icons.quiz_outlined,
                  label: '抽認卡',
                  value: '${progress.masteredFlashcards}/${progress.totalFlashcards} 已掌握',
                  progress: progress.flashcardProgress,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
              ],
              // 測驗正確率
              if (progress.totalQuizAttempts > 0)
                _buildProgressItem(
                  icon: Icons.check_circle_outline,
                  label: '測驗正確率',
                  value: '${progress.correctAnswers}/${progress.totalQuizAttempts} 題',
                  progress: progress.quizAccuracy,
                  color: Colors.purple,
                ),
              // 最後學習時間
              if (progress.lastFlashcardStudyAt != null || progress.lastQuizAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '最後學習: ${_formatLastStudyTime(progress)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatLastStudyTime(LearningProgress progress) {
    DateTime? lastTime;
    
    if (progress.lastFlashcardStudyAt != null && progress.lastQuizAt != null) {
      lastTime = progress.lastFlashcardStudyAt!.isAfter(progress.lastQuizAt!)
          ? progress.lastFlashcardStudyAt
          : progress.lastQuizAt;
    } else {
      lastTime = progress.lastFlashcardStudyAt ?? progress.lastQuizAt;
    }
    
    if (lastTime == null) return '無紀錄';
    
    final now = DateTime.now();
    final diff = now.difference(lastTime);
    
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    
    return '${lastTime.month}/${lastTime.day}';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(projectId: widget.projectId),
      ),
    );
  }

  void _openFlashcards() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardsScreen(projectId: widget.projectId),
      ),
    );
  }

  void _openQuestions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionsScreen(projectId: widget.projectId),
      ),
    );
  }

  void _openNotes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotesScreen(projectId: widget.projectId),
      ),
    );
  }

  /// 編輯專案名稱與描述
  Future<void> _editProjectName() async {
    final projectService = ProjectService();
    final project = await projectService.getProject(widget.projectId);
    
    if (project == null) return;
    
    final nameController = TextEditingController(text: _currentTitle);
    final descriptionController = TextEditingController(text: project.description ?? '');
    
    final colorOptions = [
      {'name': 'Blue', 'value': '#2196F3'},
      {'name': 'Green', 'value': '#4CAF50'},
      {'name': 'Orange', 'value': '#FF9800'},
      {'name': 'Purple', 'value': '#9C27B0'},
      {'name': 'Red', 'value': '#F44336'},
      {'name': 'Pink', 'value': '#E91E63'},
      {'name': 'Teal', 'value': '#009688'},
      {'name': 'Indigo', 'value': '#3F51B5'},
    ];
    String? selectedColor = project.colorTag ?? colorOptions[0]['value'];
    
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '編輯專案資訊',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '專案名稱',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '輸入專案名稱',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '專案描述 (選填)',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '輸入專案描述',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '顏色標籤',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((color) {
                    final colorValue = color['value']!;
                    final isSelected = selectedColor == colorValue;
                    final colorInt = int.parse(colorValue.substring(1), radix: 16) + 0xFF000000;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = colorValue),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(colorInt),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Color(colorInt).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'name': nameController.text,
                'description': descriptionController.text,
                'colorTag': selectedColor,
              }),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final newName = result['name']?.trim();
      final newDescription = result['description']?.trim();
      final newColorTag = result['colorTag'];
      
      if (newName != null && newName.isNotEmpty) {
        try {
          final updatedProject = project.copyWith(
            title: newName,
            description: newDescription?.isEmpty == true ? null : newDescription,
            colorTag: newColorTag,
            lastUpdatedAt: DateTime.now(),
          );
          await projectService.updateProject(updatedProject);
          
          setState(() {
            _currentTitle = newName;
          });
          
          if (!mounted) return;
          ToastUtils.success(context, '專案資訊已更新');
        } catch (e) {
          if (!mounted) return;
          ToastUtils.error(context, '更新失敗: $e');
        }
      }
    }
  }

  /// AI 智能命名
  Future<void> _aiGenerateName() async {
    try {
      final projectService = ProjectService();
      final files = await projectService.watchFiles(widget.projectId).first;
      
      if (files.isEmpty) {
        if (!mounted) return;
        ToastUtils.info(context, '請先上傳檔案，AI 才能根據內容建議名稱');
        return;
      }

      // 顯示載入對話框
      if (!mounted) return;
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
                    'AI 正在分析...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '正在根據您上傳的 ${files.length} 個檔案生成最適當的專案名稱',
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

      // 收集檔案資訊和已提取的文字
      final StringBuffer contextBuffer = StringBuffer();
      contextBuffer.writeln('專案中的檔案清單：');
      
      for (final file in files) {
        contextBuffer.writeln('- ${file.name} (${file.type.toUpperCase()}, ${file.category})');
        
        // 如果有提取的文字，加入前 500 字
        if (file.extractedText != null && file.extractedText!.isNotEmpty) {
          final preview = file.extractedText!.length > 500 
              ? '${file.extractedText!.substring(0, 500)}...' 
              : file.extractedText!;
          contextBuffer.writeln('  內容預覽: $preview');
        }
      }

      // 使用 Gemini 生成專案名稱
      final geminiService = GeminiService();
      final prompt = '''
請根據以下專案的檔案資訊，生成一個簡潔、準確、有意義的專案名稱。

${contextBuffer.toString()}

要求：
1. 名稱要能反映專案的主題或內容
2. 長度控制在 2-6 個中文字或 3-20 個英文字
3. 使用清晰、專業的命名
4. 只返回專案名稱，不要有任何額外說明或標點符號

專案名稱：''';

      final suggestedName = await geminiService.generateText(prompt: prompt);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // 關閉載入對話框
      
      final cleanedName = suggestedName.trim()
          .replaceAll('「', '')
          .replaceAll('」', '')
          .replaceAll('『', '')
          .replaceAll('』', '')
          .replaceAll('"', '')
          .replaceAll("'", '');
      
      if (cleanedName.isEmpty) {
        ToastUtils.error(context, 'AI 命名失敗，請重試');
        return;
      }

      // 顯示建議的名稱並詢問是否使用
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('AI 建議名稱', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '根據您的檔案內容，AI 建議將專案命名為：',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  cleanedName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '當前名稱：$_currentTitle',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('保持原名稱', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('使用 AI 名稱'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final project = await projectService.getProject(widget.projectId);
          
          if (project != null) {
            final updatedProject = project.copyWith(title: cleanedName);
            await projectService.updateProject(updatedProject);
            
            setState(() {
              _currentTitle = cleanedName;
            });
            
            if (!mounted) return;
            ToastUtils.success(context, '✨ 專案已使用 AI 建議名稱');
          }
        } catch (e) {
          if (!mounted) return;
          ToastUtils.error(context, '更新失敗: $e');
        }
      }
    } catch (e) {
      // 確保關閉 loading dialog
      if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}
      }
      
      if (!mounted) return;
      ToastUtils.error(context, 'AI 命名失敗: $e');
    }
  }
}

// 分類篩選器固定 Header Delegate
class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryFilterDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 56.0; // 高度

  @override
  double get minExtent => 56.0; // 高度

  @override
  bool shouldRebuild(covariant _CategoryFilterDelegate oldDelegate) {
    // 只有當 child 真的改變時才重建
    return child != oldDelegate.child;
  }
}
