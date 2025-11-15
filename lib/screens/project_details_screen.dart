import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

import '../models/file_model.dart';
import '../services/project_service.dart';
import '../services/subscription_service.dart';
import '../services/storage_service.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key, required this.projectId, required this.title});

  final String projectId;
  final String title;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {

  @override
  Widget build(BuildContext context) {
    final projectService = ProjectService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
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
          if (snapshot.connectionState == ConnectionState.waiting) {
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
            slivers: [
              // 檔案統計區域
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildStatsCard(files),
                ),
              ),
              
              // 檔案列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final file = files[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFileCard(context, file),
                      );
                    },
                    childCount: files.length,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先登入')),
        );
        return;
      }

      // 選擇檔案
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'txt', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      // 檢查單檔大小限制 (10MB)
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      for (final f in result.files) {
        if (f.size > maxFileSize) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('檔案大小超過 10MB 上限，已取消上傳。')),
          );
          return;
        }
      }

      // 獲取訂閱和當前檔案數量
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

      // 顯示上傳進度
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在上傳 ${result.files.length} 個檔案...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // 上傳檔案
      final storage = const StorageService();
      final projectService = ProjectService();
      int successCount = 0;

      for (final f in result.files) {
        if (f.path == null) continue;
        
        try {
          final file = File(f.path!);
          final now = DateTime.now();
          final fileId = '${now.microsecondsSinceEpoch}-${f.name}';
          
          String storageType = 'local';
          String? localPath;
          String? cloudPath;
          String? downloadUrl;

          if (subscription.isPro) {
            final uploaded = await storage.uploadToCloudflare(
              file: file,
              projectId: widget.projectId,
              userId: user.uid,
              subscription: subscription,
            );
            storageType = 'cloud';
            cloudPath = uploaded['cloudPath'];
            downloadUrl = uploaded['downloadUrl'];
          } else {
            localPath = await storage.saveToLocal(file, widget.projectId);
          }

          final meta = FileModel(
            id: fileId,
            projectId: widget.projectId,
            name: f.name,
            type: (f.extension ?? '').toLowerCase(),
            sizeBytes: f.size,
            storageType: storageType,
            localPath: localPath,
            cloudPath: cloudPath,
            downloadUrl: downloadUrl,
            uploaderId: user.uid,
            uploadedAt: now,
            metadata: const {},
          );

          await projectService.addFileMetadata(widget.projectId, meta);
          successCount++;
        } catch (e) {
          print('上傳檔案 ${f.name} 失敗: $e');
        }
      }

      if (!mounted) return;
      final storageInfo = subscription.isPro 
          ? '已上傳到雲端儲存 (Cloudflare R2)' 
          : '已儲存到本地裝置';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 成功上傳 $successCount 個檔案\n$storageInfo'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上傳失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 開啟檔案
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('無法開啟檔案: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('刪除檔案', style: TextStyle(color: Colors.white)),
        content: Text(
          '確定要刪除「${file.name}」嗎？\n此操作無法復原。',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 檔案已刪除'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openFile(context, file),
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
                      Row(
                        children: [
                          Text(
                            file.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
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
                            ' · ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
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
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }
}


