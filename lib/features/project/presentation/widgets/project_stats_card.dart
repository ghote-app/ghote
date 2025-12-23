import 'package:flutter/material.dart';
import '../../../../utils/app_locale.dart';

/// Widget for displaying project file stats header
/// Refined to only show title, total size, and icon-only upload button
class ProjectStatsCard extends StatelessWidget {
  final VoidCallback onUpload;
  final int totalSize;

  const ProjectStatsCard({
    super.key,
    required this.onUpload,
    required this.totalSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.white.withValues(alpha: 0.6),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            tr('project.stats'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Total Size Text
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_outlined,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  Text(
                    _formatSize(totalSize),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
          // Icon-only Upload Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onUpload,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
            ),
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
}
