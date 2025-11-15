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
// import 'upgrade_screen.dart';
import 'settings_screen.dart';
import 'project_details_screen.dart';

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.title,
    required this.status,
    required this.documentCount,
    required this.lastUpdated,
    required this.image,
    required this.progress,
    required this.category,
  });
  final String id;
  final String title;
  final String status;
  final int documentCount;
  final String lastUpdated;
  final String image;
  final double progress;
  final String category;
}

// sample projects removed; now binding to Firestore only

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userName, this.onLogout});
  final String? userName;
  final VoidCallback? onLogout;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  String _selectedFilter = 'All';
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
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
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayName?.isNotEmpty == true ? _displayName! : (widget.userName ?? "User"),
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search projects, documents...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
          suffixIcon: Icon(Icons.tune_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDense: true,
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
                  Expanded(child: _buildStatCard('Active', '0', Icons.play_circle_outline_rounded, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Completed', '0', Icons.check_circle_outline_rounded, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Archived', '0', Icons.archive_outlined, Colors.grey)),
                ],
              )
            : StreamBuilder<List<Project>>(
                stream: ProjectService().watchProjectsByOwner(user.uid),
                builder: (context, snapshot) {
                  final projects = snapshot.data ?? <Project>[];
                  final active = projects.where((p) => p.status == 'Active').length;
                  final completed = projects.where((p) => p.status == 'Completed').length;
                  final archived = projects.where((p) => p.status == 'Archived').length;
                  return Row(
                    children: <Widget>[
                      Expanded(child: _buildStatCard('Active', '$active', Icons.play_circle_outline_rounded, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Completed', '$completed', Icons.check_circle_outline_rounded, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Archived', '$archived', Icons.archive_outlined, Colors.grey)),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Active', 'Completed', 'Archived'];
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildFilterChip(filter, isSelected),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = label),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: (isSelected ? Colors.white : Colors.white24).withValues(alpha: 0.08),
            border: Border.all(color: isSelected ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.15), width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
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
              Icon(Icons.login_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Please sign in to view your projects', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18, fontWeight: FontWeight.w500)),
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
              child: Text('Failed to load projects: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
            );
          }
          var projects = snapshot.data ?? <Project>[];

          // 套用篩選與搜尋
          if (_selectedFilter != 'All') {
            projects = projects.where((p) => p.status == _selectedFilter).toList();
          }
          if (_searchController.text.isNotEmpty) {
            final q = _searchController.text.toLowerCase();
            projects = projects.where((p) =>
              p.title.toLowerCase().contains(q) || (p.category ?? '').toLowerCase().contains(q)
            ).toList();
          }

          if (projects.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.folder_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No projects yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Tap + to create your first project', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
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
                  final fileCount = fileSnapshot.hasData ? fileSnapshot.data!.length : 0;
                  
                  final item = ProjectItem(
                    id: p.id,
                    title: p.title,
                    status: p.status,
                    documentCount: fileCount,
                    lastUpdated: _formatRelative(p.lastUpdatedAt),
                    image: 'assets/AppIcon/Ghote_icon_black_background.png',
                    progress: p.status == 'Completed' ? 1.0 : 0.5,
                    category: p.category ?? 'General',
                  );
                  
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.08;
                      final animationPercent = Curves.easeOutCubic.transform(
                        math.max(0.0, (_animationController.value - delay) / (1.0 - delay)),
                      );
                      return Opacity(
                        opacity: animationPercent,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - animationPercent)),
                          child: Transform.scale(
                            scale: 0.95 + (0.05 * animationPercent),
                            child: _ProjectCard(
                              item: item,
                              onDelete: () => _confirmDeleteProject(item.id),
                              onTap: () => _navigateToProjectDetails(item),
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
      ),
    );
  }
  void _navigateToProjectDetails(ProjectItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(
          projectId: item.id,
          title: item.title,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProject(String projectId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Delete project?', style: TextStyle(color: Colors.white)),
        content: const Text('This will delete the project and its files metadata. This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ProjectService().deleteProjectDeep(projectId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted')));
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
  Future<({int count, Subscription sub})> _getUserProjectCountAndSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    final sub = await SubscriptionService().getUserSubscription(user?.uid ?? '');
    final projects = await ProjectService().watchProjectsByOwner(user!.uid).first;
    return (count: projects.length, sub: sub);
  }

  /// Show dialog for user to select a project
  Future<Project?> _promptProjectSelection(BuildContext context, List<Project> projects) async {
    if (projects.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('No Projects', style: TextStyle(color: Colors.white)),
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
        title: const Text('Select Project', style: TextStyle(color: Colors.white)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Create or add', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                _fabAction(
                  icon: Icons.create_new_folder_rounded,
                  title: 'Create project',
                  subtitle: 'Create a container for your study materials',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(context);
                    await _createNewProject();
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
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewProject() async {
    // Check project count limit before creating
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }

    final data = await _getUserProjectCountAndSubscription();
    if ((data.sub.isFree || data.sub.isPlus) && data.count >= 3) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Project Limit Reached', style: TextStyle(color: Colors.white)),
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
      return;
    }

    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final statusOptions = ['Active', 'Completed', 'Archived'];
    String status = 'Active';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Create project', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  hintText: 'Project title',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: categoryController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  hintText: 'Category (optional)',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: status,
              items: statusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => status = v ?? 'Active',
              decoration: const InputDecoration(hintText: 'Status', hintStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final title = nameController.text.trim();
              final category = categoryController.text.trim().isEmpty ? null : categoryController.text.trim();
              if (title.isEmpty) return;
              final now = DateTime.now();
              final project = Project(
                id: 'p_${now.microsecondsSinceEpoch}',
                title: title,
                description: null,
                ownerId: user.uid,
                collaboratorIds: const <String>[],
                createdAt: now,
                lastUpdatedAt: now,
                status: status,
                category: category,
              );
              await ProjectService().createProject(project);
              if (mounted) Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project created')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFlow() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
        return;
      }

      // Get user's projects
      final projects = await ProjectService().watchProjectsByOwner(user.uid).first;
      
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('檔案大小超過 10MB 上限，已取消上傳。')),
          );
          return;
        }
      }

      // Get subscription and current file count
      final subscription = await SubscriptionService().getUserSubscription(user.uid);
      final currentFileCount = await ProjectService().getProjectFileCount(selectedProject.id);

      // Check file count limit for Free/Plus users (10 files per project)
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

      // Show storage limit notice for Free/Plus users
      if (subscription.isFree || subscription.isPlus) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Using limited cloud storage (Free/Plus). Upgrade for unlimited.')),
        );
      }

      // Upload files
      final storage = const StorageService();
      final projectService = ProjectService();
      for (final f in result.files) {
        if (f.path == null) continue;
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
            projectId: selectedProject.id,
            userId: user.uid,
            subscription: subscription,
          );
          storageType = 'cloud';
          cloudPath = uploaded['cloudPath'];
          downloadUrl = uploaded['downloadUrl'];
        } else {
          localPath = await storage.saveToLocal(file, selectedProject.id);
        }
        final meta = FileModel(
          id: fileId,
          projectId: selectedProject.id,
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
        await projectService.addFileMetadata(selectedProject.id, meta);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded ${result.files.length} file(s)')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
        allowedExtensions: ['jpg', 'png', 'pdf', 'txt', 'doc', 'docx'],
      );
    } catch (e) {
      rethrow;
    }
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.item,
    required this.onDelete,
    required this.onTap,
  });
  final ProjectItem item;
  final VoidCallback onDelete;
  final VoidCallback onTap;

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
              border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 10)),
                BoxShadow(color: _getStatusColor().withOpacity(0.16), blurRadius: 24, spreadRadius: 1),
              ],
            ),
            child: Material(
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
                                color: _getStatusColor().withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _getStatusColor().withValues(alpha: 0.32), width: 1),
                              ),
                              child: Image.asset(item.image, width: 26, height: 26, fit: BoxFit.cover),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _getStatusColor().withValues(alpha: 0.36), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 14),
                                  const SizedBox(width: 6),
                                  Text(item.status, style: TextStyle(color: _getStatusColor(), fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              color: const Color(0xFF121212),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
                              onSelected: (value) async {
                                if (value == 'delete') onDelete();
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'open', child: Text('Open')), 
                                const PopupMenuItem(value: 'archive', child: Text('Archive')), 
                                const PopupMenuItem(value: 'delete', child: Text('Delete')), 
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Text(
                            item.title,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.local_offer_outlined, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                            const SizedBox(width: 6),
                            Text(item.category, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Icon(Icons.description_outlined, color: Colors.white.withValues(alpha: 0.6), size: 16),
                            const SizedBox(width: 6),
                            Text('${item.documentCount} docs', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.6), size: 16),
                            const SizedBox(width: 6),
                            Text(item.lastUpdated, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}