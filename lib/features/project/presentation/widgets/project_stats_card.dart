import 'package:flutter/material.dart';

import '../../../../models/file_model.dart';
import '../../../../utils/app_locale.dart';

/// Widget for displaying project file statistics
/// Extracted from project_details_screen.dart for Clean Architecture
class ProjectStatsCard extends StatelessWidget {
  final List<FileModel> files;

  const ProjectStatsCard({
    super.key,
    required this.files,
  });

  @override
  Widget build(BuildContext context) {
    final totalSize = files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    final cloudFiles = files.where((f) => f.storageType == 'cloud').length;
    final localFiles = files.where((f) => f.storageType == 'local').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white.withValues(alpha: 0.6), size: 18),
              const SizedBox(width: 8),
              Text(
                tr('project.stats'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(tr('project.fileCount'), '${files.length}', Icons.description_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(tr('project.totalSize'), _formatSize(totalSize), Icons.storage_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(tr('project.cloudFiles'), '$cloudFiles', Icons.cloud_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(tr('project.localFiles'), '$localFiles', Icons.phone_android_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    const int kb = 1024;
    const int mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
