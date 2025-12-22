import 'package:flutter/material.dart';
import '../../../../utils/app_locale.dart';
import 'project_item.dart';

/// A card widget representing a project in the dashboard grid
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onTap,
    required this.onArchive,
  });
  
  final ProjectItem item;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  Color _getStatusColor() {
    switch (item.status) {
      case 'Active':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      case 'Archived':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon() {
    switch (item.status) {
      case 'Active':
        return Icons.play_circle_filled_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Archived':
        return Icons.archive_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, scale, _) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _getStatusColor().withOpacity(0.16),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Color accent bar on left edge
                if (item.colorTag != null)
                  Positioned(
                    left: 0,
                    top: 16,
                    bottom: 16,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(item.colorTag!.substring(1), radix: 16) +
                              0xFF000000,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(
                              int.parse(
                                    item.colorTag!.substring(1),
                                    radix: 16,
                                  ) +
                                  0xFF000000,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onTap,
                    onLongPress: () {},
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _getStatusColor().withValues(
                                        alpha: 0.32,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Image.asset(
                                    item.image,
                                    width: 26,
                                    height: 26,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _getStatusColor().withValues(
                                        alpha: 0.36,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        _getStatusIcon(),
                                        color: _getStatusColor(),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.status,
                                        style: TextStyle(
                                          color: _getStatusColor(),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  color: const Color(0xFF1A1A1A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.more_horiz_rounded,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'open') {
                                      onTap();
                                    } else if (value == 'archive') {
                                      onArchive();
                                    } else if (value == 'delete') {
                                      onDelete();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'open',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.open_in_new_rounded,
                                            color: Colors.blue.withValues(
                                              alpha: 0.8,
                                            ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            tr('common.open'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.status == 'Archived'
                                                ? Icons.unarchive_rounded
                                                : Icons.archive_rounded,
                                            color: Colors.orange.withValues(
                                              alpha: 0.8,
                                            ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            item.status == 'Archived'
                                                ? tr('project.unarchive')
                                                : tr('project.archive'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red.withValues(
                                              alpha: 0.8,
                                            ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            tr('common.delete'),
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (item.description != null &&
                                item.description!.isNotEmpty) ...[
                              Text(
                                item.description!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.category,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: item.progress,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getStatusColor(),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.description_outlined,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${item.documentCount} ${tr("common.docs")}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.lastUpdated,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
