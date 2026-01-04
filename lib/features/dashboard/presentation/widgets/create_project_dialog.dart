import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/project.dart';
import '../../../../models/file_model.dart';
import '../../../../services/project_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../utils/toast_utils.dart';

/// Dialog for creating a new project
class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key, required this.onCreated});

  final VoidCallback? onCreated;

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  final List<String> _statusOptions = ['Active', 'Completed', 'Archived'];
  final List<Map<String, String>> _colorOptions = [
    {'name': 'Blue', 'value': '#2196F3'},
    {'name': 'Green', 'value': '#4CAF50'},
    {'name': 'Orange', 'value': '#FF9800'},
    {'name': 'Purple', 'value': '#9C27B0'},
    {'name': 'Red', 'value': '#F44336'},
    {'name': 'Pink', 'value': '#E91E63'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Indigo', 'value': '#3F51B5'},
  ];

  String _status = 'Active';
  String? _selectedColor = '#2196F3';
  bool _isCreating = false;

  // File Upload State
  final List<PlatformFile> _selectedFiles = [];
  bool _isPickingFile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // 根據副檔名判斷檔案分類 (Coupled from DashboardScreen logic - ideally should be in a utility)
  String _getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if ([
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'odt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'csv',
    ].contains(ext))
      return 'document';
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'svg',
      'webp',
      'ico',
      'tiff',
      'heic',
    ].contains(ext))
      return 'image';
    if ([
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'mkv',
      'webm',
      'm4v',
      '3gp',
    ].contains(ext))
      return 'video';
    if (['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'].contains(ext))
      return 'audio';
    return 'other';
  }

  Future<void> _pickFiles() async {
    // Check file count limit logic
    // We do a pre-check assuming 0 existing files since it's a NEW project.
    // However, we must check if adding these files exceeds the limit per project logic found in dashboard.
    // But since the project is new, we just check against the absolute limit (e.g. 10 files for free).

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isPickingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'png',
          'pdf',
          'txt',
          'doc',
          'docx',
          'mp3',
          'wav',
          'm4a',
          'ogg',
          'flac',
          'aac',
          'wma',
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        // Check size limit (10MB)
        const maxFileSize = 10 * 1024 * 1024;
        final validFiles = <PlatformFile>[];
        bool sizeError = false;

        for (final f in result.files) {
          if (f.size > maxFileSize) {
            sizeError = true;
          } else {
            validFiles.add(f);
          }
        }

        if (sizeError && mounted) {
          ToastUtils.warning(
            context,
            'Some files were skipped because they exceed 10MB.',
          );
        }

        // Check subscription limit (10 files max for Free/Plus)
        // Since we are creating a NEW project, currentFileCount is 0.
        // We only check against the validFiles + currently selected files.
        final subscription = await SubscriptionService().getUserSubscription(
          user.uid,
        );
        if (subscription.isFree || subscription.isPlus) {
          final totalFiles = _selectedFiles.length + validFiles.length;
          if (totalFiles > 10) {
            if (mounted) {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text(
                    'File Limit Exceeded',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Free/Plus plans allow max 10 files per project. Please upgrade for unlimited.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        }

        setState(() {
          _selectedFiles.addAll(validFiles);
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.error(context, 'Failed to pick files: $e');
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Select Color',
          style: TextStyle(color: Colors.white),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((color) {
            final colorValue = color['value']!;
            final isSelected = _selectedColor == colorValue;
            final colorInt =
                int.parse(colorValue.substring(1), radix: 16) + 0xFF000000;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = colorValue);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(colorInt),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(colorInt).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _createProject() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ToastUtils.info(context, 'Please sign in first');
      return;
    }

    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ToastUtils.warning(context, 'Please enter a project title');
      return;
    }

    if (_selectedFiles.isEmpty) {
      ToastUtils.warning(context, 'Please add at least one file to proceed');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final category = _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim();

      final now = DateTime.now();
      final projectId = 'p_${now.microsecondsSinceEpoch}';

      final project = Project(
        id: projectId,
        title: title,
        description: description,
        ownerId: user.uid,
        collaboratorIds: const <String>[],
        createdAt: now,
        lastUpdatedAt: now,
        status: _status,
        category: category,
        colorTag: _selectedColor,
      );

      // 1. Create Project
      await ProjectService().createProject(project);

      // 2. Upload Files if any
      if (_selectedFiles.isNotEmpty) {
        final storage = const StorageService();
        final projectService = ProjectService();

        for (final f in _selectedFiles) {
          try {
            if (f.path == null) continue;
            final file = File(f.path!);
            final fileId = '${DateTime.now().microsecondsSinceEpoch}-${f.name}';

            // Save to local storage
            final localPath = await storage.saveToLocal(file, projectId);

            final meta = FileModel(
              id: fileId,
              projectId: projectId,
              name: f.name,
              type: (f.extension ?? '').toLowerCase(),
              category: _getCategoryFromExtension(f.extension ?? ''),
              sizeBytes: f.size,
              storageType: 'local',
              localPath: localPath,
              cloudPath: null,
              downloadUrl: null,
              uploaderId: user.uid,
              uploadedAt: DateTime.now(),
              metadata: const {},
            );

            await projectService.addFileMetadata(projectId, meta);
          } catch (e) {
            print('Error uploading file ${f.name}: $e');
            // We continue even if one fails, effectively "best effort"
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ToastUtils.success(context, '✅ Project created successfully');
        widget.onCreated?.call();
      }
    } catch (e) {
      if (mounted) ToastUtils.error(context, 'Error creating project: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Create Project',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 600, // Ensure it's wide enough for the rows
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      label: 'Project Title',
                      controller: _nameController,
                      hint: 'Enter project title',
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildStatusDropdown(),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              _buildTextField(
                label: 'Description (Optional)',
                controller: _descriptionController,
                hint: 'Enter project description',
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Row 2: Category & Color
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Category (Optional)',
                      controller: _categoryController,
                      hint: 'e.g., Study, Work',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 2,
                    ), // Align with text field
                    child: _buildColorCircle(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Add Files Section
              const Text(
                'Add Files (Required)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              if (_selectedFiles.isEmpty)
                _buildAddFileBox()
              else
                _buildFileList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createProject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Create',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(maxLines > 1 ? 10 : 8),
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 15,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle() {
    final colorInt =
        int.parse(_selectedColor?.substring(1) ?? '2196F3', radix: 16) +
        0xFF000000;
    return GestureDetector(
      onTap: _showColorPicker,
      child: Column(
        children: [
          const SizedBox(height: 4), // Visual alignment
          Container(
            width: 48, // Match input height roughly
            height: 48,
            decoration: BoxDecoration(
              color: Color(colorInt),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.palette_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          initialValue: _status,
          tooltip: 'Select Status',
          color: const Color(0xFF1E1E1E),
          surfaceTintColor: const Color(0xFF1E1E1E),
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          onSelected: (v) => setState(() => _status = v),
          itemBuilder: (context) => _statusOptions.map((e) {
            final (sColor, sIcon) = _getStatusStyle(e);
            return PopupMenuItem<String>(
              value: e,
              child: Row(
                children: [
                  Icon(sIcon, color: sColor, size: 20),
                  const SizedBox(width: 12),
                  Text(e, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
          child: Container(
            height: 48,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Builder(
              builder: (context) {
                final (color, icon) = _getStatusStyle(_status);
                return Icon(icon, color: color, size: 24);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFileBox({bool compact = false}) {
    return InkWell(
      onTap: _pickFiles,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: compact ? 60 : 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
            style: BorderStyle
                .solid, // Consider dotted if possible using package, but solid is safer for standard icons
          ),
        ),
        child: _isPickingFile
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: compact ? 24 : 32,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add files',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildFileList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _selectedFiles.length + 1,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        itemBuilder: (context, index) {
          if (index == _selectedFiles.length) {
            return ListTile(
              dense: true,
              onTap: _pickFiles,
              leading: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.blue, size: 16),
              ),
              title: const Text(
                'Add more files',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final file = _selectedFiles[index];
          final ext = file.extension ?? '';
          // Simple icon logic
          IconData icon = Icons.insert_drive_file;
          if (['jpg', 'png', 'jpeg'].contains(ext)) icon = Icons.image;
          if (['pdf'].contains(ext)) icon = Icons.picture_as_pdf;

          return ListTile(
            dense: true,
            leading: Icon(icon, color: Colors.white70, size: 20),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            subtitle: Text(
              '${(file.size / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              onPressed: () => _removeFile(file),
            ),
          );
        },
      ),
    );
  }

  (Color, IconData) _getStatusStyle(String status) {
    return switch (status) {
      'Active' => (const Color(0xFF4ADE80), Icons.play_circle_outline_rounded),
      'Completed' => (
        const Color(0xFF60A5FA),
        Icons.check_circle_outline_rounded,
      ),
      'Archived' => (const Color(0xFFFF9800), Icons.archive_outlined),
      _ => (Colors.white70, Icons.circle_outlined),
    };
  }
}

/// Helper function to check project limit before showing the dialog
Future<bool> checkProjectLimitAndShowDialog(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ToastUtils.info(context, 'Please sign in first');
    return false;
  }

  final subscription = await SubscriptionService().getUserSubscription(
    user.uid,
  );
  // Using .first to get current snapshot
  final projects = await ProjectService().watchProjectsByOwner(user.uid).first;
  final projectCount = projects.length;

  if ((subscription.isFree || subscription.isPlus) && projectCount >= 3) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Project Limit Reached',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Free/Plus plans allow max 3 projects. Please upgrade to Ghote Pro for unlimited projects.',
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
    }
    return false;
  }
  return true;
}
