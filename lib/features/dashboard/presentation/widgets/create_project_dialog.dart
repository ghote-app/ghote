import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/project.dart';
import '../../../../services/project_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../utils/toast_utils.dart';

/// Dialog for creating a new project
class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({
    super.key,
    required this.onCreated,
  });

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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
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

    setState(() => _isCreating = true);

    try {
      final description = _descriptionController.text.trim().isEmpty
          ? null : _descriptionController.text.trim();
      final category = _categoryController.text.trim().isEmpty
          ? null : _categoryController.text.trim();
      
      final now = DateTime.now();
      final project = Project(
        id: 'p_${now.microsecondsSinceEpoch}',
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
      
      await ProjectService().createProject(project);
      
      if (mounted) {
        Navigator.of(context).pop();
        ToastUtils.success(context, '✅ Project created successfully');
        widget.onCreated?.call();
      }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Project Title',
              controller: _nameController,
              hint: 'Enter project title',
              autofocus: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Description (Optional)',
              controller: _descriptionController,
              hint: 'Enter project description',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Category (Optional)',
              controller: _categoryController,
              hint: 'e.g., Study, Work, Personal',
            ),
            const SizedBox(height: 16),
            _buildColorSelector(),
            const SizedBox(height: 16),
            _buildStatusDropdown(),
          ],
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color Tag',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorOptions.map((color) {
            final colorValue = color['value']!;
            final isSelected = _selectedColor == colorValue;
            final colorInt = int.parse(colorValue.substring(1), radix: 16) + 0xFF000000;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = colorValue),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(colorInt),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: Color(colorInt).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
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
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              value: _status,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              items: _statusOptions.map((e) {
                final (statusColor, statusIcon) = _getStatusStyle(e);
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 10),
                      Text(e, style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      )),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _status = v ?? 'Active'),
            ),
          ),
        ),
      ],
    );
  }

  (Color, IconData) _getStatusStyle(String status) {
    return switch (status) {
      'Active' => (const Color(0xFF4ADE80), Icons.play_circle_outline_rounded),
      'Completed' => (const Color(0xFF60A5FA), Icons.check_circle_outline_rounded),
      'Archived' => (const Color(0xFF9CA3AF), Icons.archive_outlined),
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

  final subscription = await SubscriptionService().getUserSubscription(user.uid);
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
            '免費/Plus 方案最多建立 3 個專案。請升級到 Ghote Pro 享受無限專案。',
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
