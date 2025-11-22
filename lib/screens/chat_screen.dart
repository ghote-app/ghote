import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/project_service.dart';
import '../services/storage_service.dart';
import '../models/file_model.dart';
import '../utils/toast_utils.dart';

class ChatScreen extends StatefulWidget {
  final String projectId;

  const ChatScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final ProjectService _projectService = ProjectService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<FileModel> _selectedImages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _selectImagesFromProject() async {
    try {
      final files = await _projectService.watchFiles(widget.projectId).first;
      final imageFiles = files.where((f) {
        final type = f.type.toLowerCase();
        return ['jpg', 'jpeg', 'png', 'bmp', 'gif'].contains(type);
      }).toList();

      if (imageFiles.isEmpty) {
        if (!mounted) return;
        ToastUtils.info(context, '專案中沒有圖片檔案');
        return;
      }

      if (!mounted) return;
      final selected = await showDialog<List<FileModel>>(
        context: context,
        builder: (context) => _ImageSelectionDialog(
          images: imageFiles,
          selectedImages: _selectedImages,
        ),
      );

      if (selected != null) {
        setState(() {
          _selectedImages = selected;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, '獲取圖片失敗: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _messageController.clear();
    });

    try {
      // 準備圖片數據
      List<DataPart>? imageParts;
      if (_selectedImages.isNotEmpty) {
        imageParts = [];
        for (final imageFile in _selectedImages) {
          try {
            Uint8List imageBytes;
            if (imageFile.storageType == 'local' && imageFile.localPath != null) {
              imageBytes = await File(imageFile.localPath!).readAsBytes();
            } else {
              // 從雲端獲取
              final storageService = const StorageService();
              imageBytes = await storageService.getFileContent(imageFile);
            }
            imageParts.add(DataPart('image/jpeg', imageBytes));
          } catch (e) {
            print('讀取圖片失敗: ${imageFile.name}, 錯誤: $e');
          }
        }
      }

      await for (final _ in _chatService.sendMessage(
        projectId: widget.projectId,
        userMessage: message,
        imageParts: imageParts,
      )) {
        _scrollToBottom();
      }

      // 清除已選擇的圖片
      if (mounted) {
        setState(() {
          _selectedImages = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, '發送失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('清除對話', style: TextStyle(color: Colors.white)),
        content: const Text(
          '確定要清除所有對話記錄嗎？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.clearChatHistory(widget.projectId);
        if (!mounted) return;
        ToastUtils.success(context, '對話已清除');
      } catch (e) {
        if (!mounted) return;
        ToastUtils.error(context, '清除失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('AI 聊天', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: _clearChat,
            tooltip: '清除對話',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.watchMessages(widget.projectId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '開始與 AI 對話',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI 會優先使用專案文件內容回答問題',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.blue, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Colors.green, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顯示已選擇的圖片
          if (_selectedImages.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image, color: Colors.blue, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                image.name.length > 8
                                    ? '${image.name.substring(0, 8)}...'
                                    : image.name,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Row(
            children: [
              // 圖片選擇按鈕
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.image, color: Colors.white70),
                  onPressed: _selectImagesFromProject,
                  tooltip: '從專案選擇圖片',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: '輸入訊息...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 圖片選擇對話框
class _ImageSelectionDialog extends StatefulWidget {
  final List<FileModel> images;
  final List<FileModel> selectedImages;

  const _ImageSelectionDialog({
    required this.images,
    required this.selectedImages,
  });

  @override
  State<_ImageSelectionDialog> createState() => _ImageSelectionDialogState();
}

class _ImageSelectionDialogState extends State<_ImageSelectionDialog> {
  late List<FileModel> _selected;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedImages);
  }

  Widget _buildImageThumbnail(FileModel image) {
    if (image.storageType == 'local' && image.localPath != null) {
      final file = File(image.localPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }
    } else if (image.downloadUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          image.downloadUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.white38, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('選擇圖片', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            final image = widget.images[index];
            final isSelected = _selected.any((f) => f.id == image.id);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                    ? Colors.blue.withValues(alpha: 0.5) 
                    : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: _buildImageThumbnail(image),
                title: Text(
                  image.name,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${image.type.toUpperCase()} • ${image.formattedSize}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(image);
                      } else {
                        _selected.removeWhere((f) => f.id == image.id);
                      }
                    });
                  },
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                ),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selected.removeWhere((f) => f.id == image.id);
                    } else {
                      _selected.add(image);
                    }
                  });
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Text('確定 (${_selected.length})'),
        ),
      ],
    );
  }
}

