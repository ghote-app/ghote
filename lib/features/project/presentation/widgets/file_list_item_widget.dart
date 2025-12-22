import 'package:flutter/material.dart';

import '../../../../models/file_model.dart';
import '../../../../utils/app_locale.dart';

/// Callback types for file actions
typedef FilePreviewCallback = void Function(BuildContext context, FileModel file);
typedef FileOptionsCallback = void Function(BuildContext context, FileModel file);

/// Widget for displaying a single file item in a list
/// Extracted from project_details_screen.dart for Clean Architecture
class FileListItemWidget extends StatelessWidget {
  final FileModel file;
  final FilePreviewCallback onTap;
  final FileOptionsCallback onLongPress;
  final IconData Function(String type) getFileIcon;
  final Color Function(String type) getFileColor;
  final String Function(String category) getCategoryLabel;
  final Color Function(String category) getCategoryColor;

  const FileListItemWidget({
    super.key,
    required this.file,
    required this.onTap,
    required this.onLongPress,
    required this.getFileIcon,
    required this.getFileColor,
    required this.getCategoryLabel,
    required this.getCategoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCloud = file.storageType == 'cloud';
    
    // FR-3.5: Processing status widget
    Widget? statusWidget = _buildStatusWidget();
    
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
            onTap: () => onTap(context, file),
            onLongPress: () => onLongPress(context, file),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // File icon
                  _buildFileIcon(),
                  const SizedBox(width: 12),
                  
                  // File info
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
                        _buildMetadata(isCloud, statusWidget),
                      ],
                    ),
                  ),
                  
                  // Arrow icon
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

  Widget? _buildStatusWidget() {
    if (file.extractionStatus == 'processing') {
      return Row(
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
            tr('file.processing'),
            style: TextStyle(
              color: Colors.blue.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (file.extractionStatus == 'extracted') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Colors.green.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            tr('file.completed'),
            style: TextStyle(
              color: Colors.green.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (file.extractionStatus == 'failed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_rounded,
            size: 14,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            tr('file.failed'),
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return null;
  }

  Widget _buildFileIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getFileColor(file.type).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getFileColor(file.type).withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        getFileIcon(file.type),
        color: getFileColor(file.type),
        size: 24,
      ),
    );
  }

  Widget _buildMetadata(bool isCloud, Widget? statusWidget) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Category label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: getCategoryColor(file.category).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: getCategoryColor(file.category).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            getCategoryLabel(file.category),
            style: TextStyle(
              color: getCategoryColor(file.category),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildDot(),
        Text(
          file.type.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        _buildDot(),
        Text(
          file.formattedSize,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        _buildDot(),
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
              isCloud ? tr('file.cloud') : tr('file.local'),
              style: TextStyle(
                color: isCloud ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        // FR-3.5: Status display
        if (statusWidget != null) ...[
          _buildDot(),
          statusWidget,
        ],
      ],
    );
  }

  Widget _buildDot() {
    return Text(
      '•',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
      ),
    );
  }
}
