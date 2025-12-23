import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/file_model.dart';
import '../models/project.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

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

  Widget _buildFilterChips() {
    final user = FirebaseAuth.instance.currentUser;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              // Scrollable filter chips
              Expanded(
                child: user == null
                    ? _buildFilterChipsList(null)
                    : StreamBuilder<List<Project>>(
                        stream: ProjectService().watchProjectsByOwner(user.uid),
                        builder: (context, snapshot) {
                          final projects = snapshot.data ?? <Project>[];
                          return _buildFilterChipsList(projects);
                        },
                      ),
              ),
              const SizedBox(width: 12),
              // Sort button
              _buildSortButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChipsList(List<Project>? projects) {
    final filters = [
      {'key': 'All', 'label': tr('dashboard.all'), 'color': Colors.white},
      {'key': 'Active', 'label': tr('dashboard.active'), 'color': Colors.green},
      {
        'key': 'Completed',
        'label': tr('dashboard.completed'),
        'color': Colors.blue,
      },
      {
        'key': 'Archived',
        'label': tr('dashboard.archived'),
        'color': Colors.orange,
      },
    ];

    // Calculate counts
    final counts = {
      'All': projects?.length ?? 0,
      'Active': projects?.where((p) => p.status == 'Active').length ?? 0,
      'Completed': projects?.where((p) => p.status == 'Completed').length ?? 0,
      'Archived': projects?.where((p) => p.status == 'Archived').length ?? 0,
    };

    return ValueListenableBuilder<String>(
      valueListenable: _selectedFilterNotifier,
      builder: (context, selectedFilter, _) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = selectedFilter == filter['key'];
            final count = counts[filter['key'] as String] ?? 0;
            return Padding(
              padding: EdgeInsets.only(
                right: index < filters.length - 1 ? 10 : 0,
              ),
              child: _buildFilterChip(
                filter['key'] as String,
                filter['label'] as String,
                count,
                filter['color'] as Color,
                isSelected,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortButton() {
    final sortOptions = [
      {
        'key': 'lastUpdated',
        'icon': Icons.update_rounded,
        'tooltip': tr('dashboard.lastUpdated'),
      },
      {
        'key': 'createdAt',
        'icon': Icons.calendar_today_rounded,
        'tooltip': tr('dashboard.createdAt'),
      },
      {
        'key': 'title',
        'icon': Icons.sort_by_alpha_rounded,
        'tooltip': tr('dashboard.nameAZ'),
      },
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

  Widget _buildFilterChip(
    String key,
    String label,
    int count,
    Color chipColor,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectedFilterNotifier.value = key,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isSelected
                ? chipColor.withValues(alpha: 0.2)
                : chipColor.withValues(alpha: 0.08),
            border: Border.all(
              color: isSelected
                  ? chipColor.withValues(alpha: 0.5)
                  : chipColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.3)
                      : chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
                        (a, b) => a.title.toLowerCase().compareTo(
                          b.title.toLowerCase(),
                        ),
                      );
                      break;
                    case 'createdAt':
                      projects.sort(
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      );
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
                            image:
                                'assets/AppIcon/Ghote_icon_black_background.png',
                            progress: p.status == 'Completed' ? 1.0 : 0.5,
                            category: p.category ?? 'General',
                            colorTag: p.colorTag,
                            description: p.description,
                          );

                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final delay = index * 0.08;
                              final animationPercent = Curves.easeOutCubic
                                  .transform(
                                    math.max(
                                      0.0,
                                      (_animationController.value - delay) /
                                          (1.0 - delay),
                                    ),
                                  );
                              return Opacity(
                                opacity: animationPercent,
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    30 * (1 - animationPercent),
                                  ),
                                  child: Transform.scale(
                                    scale: 0.95 + (0.05 * animationPercent),
                                    child: ProjectCard(
                                      item: item,
                                      onDelete: () =>
                                          _confirmDeleteProject(item.id),
                                      onTap: () =>
                                          _navigateToProjectDetails(item),
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
          onPressed: _onCreateProject,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Future<void> _onCreateProject() async {
    // Check limits first
    if (await checkProjectLimitAndShowDialog(context)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => const CreateProjectDialog(onCreated: null),
      );
    }
  }
}
