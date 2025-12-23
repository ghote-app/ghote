import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/file_model.dart';
import '../models/project.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../services/storage_service.dart';
import '../services/project_service.dart';
import '../utils/toast_utils.dart';
import '../utils/app_locale.dart';
import '../features/dashboard/presentation/widgets/widgets.dart';
// import 'upgrade_screen.dart';
import 'settings_screen.dart';
import 'project_details_screen.dart';

// sample projects removed; now binding to Firestore only


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userName, this.onLogout});
  final String? userName;
  final VoidCallback? onLogout;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  final ValueNotifier<String> _selectedFilterNotifier = ValueNotifier('All');
  final ValueNotifier<String> _sortByNotifier = ValueNotifier('lastUpdated');
  String? _displayName;

  // 根據副檔名判斷檔案分類
  String _getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');

    // 文件類型
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
    ].contains(ext)) {
      return 'document';
    }

    // 圖片類型
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
    ].contains(ext)) {
      return 'image';
    }

    // 影片類型
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
    ].contains(ext)) {
      return 'video';
    }

    // 音訊類型
    if (['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'].contains(ext)) {
      return 'audio';
    }

    return 'other';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animationController.forward();

    // Keep welcome name in sync with FirebaseAuth displayName
    _displayName = FirebaseAuth.instance.currentUser?.displayName;
    FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _displayName = user?.displayName;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _selectedFilterNotifier.dispose();
    _sortByNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          _buildSliverAppBar(),
          _buildStatsSection(),
          _buildFilterChips(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: _buildProjectsGrid(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SliverAppBar(
      backgroundColor: Colors.black,
      pinned: true,
      floating: true,
      // expandedHeight: Platform.isAndroid ? 180.0 : 200.0,
      expandedHeight: screenHeight * 0.25,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: _buildHeader(),
      ),
      bottom: PreferredSize(
        // preferredSize: Size.fromHeight(Platform.isAndroid ? 60 : 70),
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          // padding: EdgeInsets.fromLTRB(20, 0, 20, Platform.isAndroid ? 12 : 16),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset(
                    'assets/AppIcon/Ghote_icon_black_background.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 4),
                  Text(
                    tr('dashboard.welcomeBack'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayName?.isNotEmpty == true
                        ? _displayName!
                        : (widget.userName ?? "User"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // user menu removed; settings now accessible by tapping the top-left avatar

  // settings moved to SettingsScreen

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        decoration: InputDecoration(
          hintText: tr('dashboard.search'),
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 16, left: 12),
            child: Icon(
              Icons.tune_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final user = FirebaseAuth.instance.currentUser;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: user == null
            ? Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatCard(
                      'Active',
                      '0',
                      Icons.play_circle_outline_rounded,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      '0',
                      Icons.check_circle_outline_rounded,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Archived',
                      '0',
                      Icons.archive_outlined,
                      Colors.grey,
                    ),
                  ),
                ],
              )
            : StreamBuilder<List<Project>>(
                stream: ProjectService().watchProjectsByOwner(user.uid),
                builder: (context, snapshot) {
                  final projects = snapshot.data ?? <Project>[];
                  final active = projects
                      .where((p) => p.status == 'Active')
                      .length;
                  final completed = projects
                      .where((p) => p.status == 'Completed')
                      .length;
                  final archived = projects
                      .where((p) => p.status == 'Archived')
                      .length;
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildStatCard(
                          'Active',
                          '$active',
                          Icons.play_circle_outline_rounded,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          '$completed',
                          Icons.check_circle_outline_rounded,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Archived',
                          '$archived',
                          Icons.archive_outlined,
                          Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 120, // 固定高度確保所有區塊大小一致
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      letterSpacing: 0.3,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'All', 'label': tr('dashboard.all')},
      {'key': 'Active', 'label': tr('dashboard.active')},
      {'key': 'Completed', 'label': tr('dashboard.completed')},
      {'key': 'Archived', 'label': tr('dashboard.archived')},
    ];
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort options row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('dashboard.sort'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildSortButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips row
          SizedBox(
            height: 44,
            child: ValueListenableBuilder<String>(
              valueListenable: _selectedFilterNotifier,
              builder: (context, selectedFilter, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = selectedFilter == filter['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildFilterChip(filter['key']!, filter['label']!, isSelected),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    final sortOptions = [
      {'key': 'lastUpdated', 'icon': Icons.update_rounded, 'tooltip': tr('dashboard.lastUpdated')},
      {
        'key': 'createdAt',
        'icon': Icons.calendar_today_rounded,
        'tooltip': tr('dashboard.createdAt'),
      },
      {'key': 'title', 'icon': Icons.sort_by_alpha_rounded, 'tooltip': tr('dashboard.nameAZ')},
    ];

    return ValueListenableBuilder<String>(
      valueListenable: _sortByNotifier,
      builder: (context, sortBy, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: sortOptions.map((option) {
              final isSelected = sortBy == option['key'];
              return Tooltip(
                message: option['tooltip'] as String,
                child: GestureDetector(
                  onTap: () => _sortByNotifier.value = option['key'] as String,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectedFilterNotifier.value = key,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: (isSelected ? Colors.white : Colors.white24).withValues(
              alpha: 0.08,
            ),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // legacy sample filtering removed; now stats and grid bind to Firestore

  Widget _buildProjectsGrid() {
    final screenHeight = MediaQuery.of(context).size.height;
    final double targetCardHeight = screenHeight * 0.30;
    final double clampedCardHeight = targetCardHeight.clamp(220.0, 360.0);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.login_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your projects',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: StreamBuilder<List<Project>>(
        stream: ProjectService().watchProjectsByOwner(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Failed to load projects: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }
          final allProjects = snapshot.data ?? <Project>[];

          // Use ValueListenableBuilder for filter and sort
          return ValueListenableBuilder<String>(
            valueListenable: _selectedFilterNotifier,
            builder: (context, selectedFilter, _) {
              return ValueListenableBuilder<String>(
                valueListenable: _sortByNotifier,
                builder: (context, sortBy, _) {
                  var projects = List<Project>.from(allProjects);

                  // 套用篩選與搜尋
                  if (selectedFilter != 'All') {
                    projects = projects
                        .where((p) => p.status == selectedFilter)
                        .toList();
                  }
                  if (_searchController.text.isNotEmpty) {
                    final q = _searchController.text.toLowerCase();
                    projects = projects
                        .where(
                          (p) =>
                              p.title.toLowerCase().contains(q) ||
                              (p.category ?? '').toLowerCase().contains(q),
                        )
                        .toList();
                  }

                  // 套用排序
                  switch (sortBy) {
                    case 'title':
                      projects.sort(
                        (a, b) =>
                            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
                      );
                      break;
                    case 'createdAt':
                      projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      break;
                    case 'lastUpdated':
                    default:
                      projects.sort(
                        (a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt),
                      );
                      break;
                  }

                  if (projects.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_off_rounded,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No projects yet',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first project',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisExtent: clampedCardHeight,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
              final p = projects[index];

              // 使用 StreamBuilder 獲取實時文件數量
              return StreamBuilder<List<FileModel>>(
                stream: ProjectService().watchFiles(p.id),
                builder: (context, fileSnapshot) {
                  final fileCount = fileSnapshot.hasData
                      ? fileSnapshot.data!.length
                      : 0;

                  final item = ProjectItem(
                    id: p.id,
                    title: p.title,
                    status: p.status,
                    documentCount: fileCount,
                    lastUpdated: _formatRelative(p.lastUpdatedAt),
                    image: 'assets/AppIcon/Ghote_icon_black_background.png',
                    progress: p.status == 'Completed' ? 1.0 : 0.5,
                    category: p.category ?? 'General',
                    colorTag: p.colorTag,
                    description: p.description,
                  );

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.08;
                      final animationPercent = Curves.easeOutCubic.transform(
                        math.max(
                          0.0,
                          (_animationController.value - delay) / (1.0 - delay),
                        ),
                      );
                      return Opacity(
                        opacity: animationPercent,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - animationPercent)),
                          child: Transform.scale(
                            scale: 0.95 + (0.05 * animationPercent),
                            child: ProjectCard(
                              item: item,
                              onDelete: () => _confirmDeleteProject(item.id),
                              onTap: () => _navigateToProjectDetails(item),
                              onArchive: () =>
                                  _archiveProject(item.id, item.status),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToProjectDetails(ProjectItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ProjectDetailsScreen(projectId: item.id, title: item.title),
      ),
    );
  }

  Future<void> _archiveProject(String projectId, String currentStatus) async {
    try {
      final projectService = ProjectService();
      final project = await projectService.getProject(projectId);
      if (project == null) return;

      final newStatus = currentStatus == 'Archived' ? 'Active' : 'Archived';
      final updatedProject = Project(
        id: project.id,
        title: project.title,
        description: project.description,
        ownerId: project.ownerId,
        collaboratorIds: project.collaboratorIds,
        createdAt: project.createdAt,
        lastUpdatedAt: DateTime.now(),
        status: newStatus,
        category: project.category,
      );

      await projectService.updateProject(updatedProject);
      if (!mounted) return;

      ToastUtils.success(
        context,
        newStatus == 'Archived' ? '✅ Project archived' : '✅ Project unarchived',
      );
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(
        context,
        'Failed to ${currentStatus == 'Archived' ? 'unarchive' : 'archive'} project: $e',
      );
    }
  }

  Future<void> _confirmDeleteProject(String projectId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Project?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete the project and all its files metadata. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ProjectService().deleteProjectDeep(projectId);
      if (!mounted) return;
      ToastUtils.success(context, '✅ Project deleted successfully');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, 'Failed to delete project: $e');
    }
  }

  String _formatRelative(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays >= 1) return '${diff.inDays} days ago';
    if (diff.inHours >= 1) return '${diff.inHours} hours ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} minutes ago';
    return 'just now';
  }

  /// Get current project count and user subscription status
  Future<({int count, Subscription sub})>
  _getUserProjectCountAndSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    final sub = await SubscriptionService().getUserSubscription(
      user?.uid ?? '',
    );
    final projects = await ProjectService()
        .watchProjectsByOwner(user!.uid)
        .first;
    return (count: projects.length, sub: sub);
  }

  /// Show dialog for user to select a project
  Future<Project?> _promptProjectSelection(
    BuildContext context,
    List<Project> projects,
  ) async {
    if (projects.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'No Projects',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '請先建立一個 Project',
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
      return null;
    }

    return showDialog<Project>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Select Project',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                title: Text(
                  project.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  project.category ?? 'General',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project.status,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(project),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // bulk delete moved to user menu previously; retained via SettingsScreen later if needed

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _showFabMenu,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Future<void> _showFabMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Create or add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _fabAction(
                  icon: Icons.create_new_folder_rounded,
                  title: 'Create project',
                  subtitle: 'Create a container for your study materials',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    // Use a post-frame callback to show dialog after bottom sheet closes
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted) return;
                      // Check project limit first
                      if (await checkProjectLimitAndShowDialog(this.context)) {
                        if (mounted) {
                          showDialog(
                            context: this.context,
                            builder: (ctx) => const CreateProjectDialog(onCreated: null),
                          );
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _fabAction(
                  icon: Icons.file_upload_rounded,
                  title: 'Upload files to project',
                  subtitle: 'AI auto-naming by topic coming soon',
                  color: Colors.purple,
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAndUploadFlow();
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fabAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.32)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFlow() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ToastUtils.info(context, 'Please sign in first');
        return;
      }

      // Get user's projects
      final projects = await ProjectService()
          .watchProjectsByOwner(user.uid)
          .first;

      // Let user select a project
      final selectedProject = await _promptProjectSelection(context, projects);
      if (selectedProject == null) return;

      // Pick files
      final picker = await _lazyLoadFilePicker();
      final result = await picker();
      if (result == null || result.files.isEmpty) return;

      // Check single file size limit (10MB)
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      for (final f in result.files) {
        if (f.size > maxFileSize) {
          if (!mounted) return;
          ToastUtils.warning(context, '檔案大小超過 10MB 上限，已取消上傳。');
          return;
        }
      }

      // Get subscription and current file count
      final subscription = await SubscriptionService().getUserSubscription(
        user.uid,
      );

      final currentFileCount = await ProjectService().getProjectFileCount(
        selectedProject.id,
      );

      // Check file count limit for Free/Plus users (10 files per project)
      if (subscription.isFree || subscription.isPlus) {
        if (currentFileCount + result.files.length > 10) {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'File Limit Reached',
                style: TextStyle(color: Colors.white),
              ),
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

      // Show upload progress dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.black87,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  '正在上傳 ${result.files.length} 個檔案...',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );

      // Upload files to local storage
      final storage = const StorageService();
      final projectService = ProjectService();
      int successCount = 0;
      int failCount = 0;

      for (final f in result.files) {
        try {
          if (f.path == null) {
            failCount++;
            continue;
          }
          final file = File(f.path!);
          final now = DateTime.now();
          final fileId = '${now.microsecondsSinceEpoch}-${f.name}';

          // Always save to local storage
          final localPath = await storage.saveToLocal(file, selectedProject.id);

          final meta = FileModel(
            id: fileId,
            projectId: selectedProject.id,
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
          await projectService.addFileMetadata(selectedProject.id, meta);
          successCount++;
        } catch (e) {
          print('上傳檔案 ${f.name} 失敗: $e');
          failCount++;
        }
      }

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show result message
      if (!mounted) return;
      if (failCount > 0) {
        ToastUtils.warning(
          context,
          '✅ 成功上傳 $successCount 個檔案\n❌ $failCount 個檔案上傳失敗',
        );
      } else {
        ToastUtils.success(context, '✅ 成功上傳 $successCount 個檔案到本地儲存');
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.error(context, 'Upload failed: $e');
    }
  }

  // 延遲載入 file_picker，避免常駐依賴影響初始啟動時間
  Future<Future<dynamic> Function()> _lazyLoadFilePicker() async {
    // 直接返回檔案選擇呼叫（保留延遲載入的擴充介面）
    return () async => await _pickFiles();
  }

  Future<dynamic> _pickFiles() async {
    // 為保持頂層 import 簡潔，使用反射式呼叫不合適；直接依賴 file_picker
    // ignore: avoid_dynamic_calls
    try {
      // 使用 file_picker 套件
      // 由於此檔案未直接 import，改為延遲引入的方式不可行，這裡直接加上 import 更清晰
      // 將在檔案頂部加入 import 'package:file_picker/file_picker.dart';
      return await FilePicker.platform.pickFiles(
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
    } catch (e) {
      rethrow;
    }
  }
}
