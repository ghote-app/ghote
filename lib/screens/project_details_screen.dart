import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/file_model.dart';
import '../services/project_service.dart';

class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({super.key, required this.projectId, required this.title});

  final String projectId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final projectService = ProjectService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<FileModel>>(
        stream: projectService.watchFiles(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('載入錯誤：${snapshot.error}', style: const TextStyle(color: Colors.white70)),
            );
          }
          final files = snapshot.data ?? <FileModel>[];
          if (files.isEmpty) {
            return Center(
              child: Text('尚無檔案', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: Icon(Icons.description_outlined, color: Colors.white.withValues(alpha: 0.8)),
                title: Text(file.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${file.type.toUpperCase()} · ${file.formattedSize}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7)),
                onTap: () {
                  // 後續導向預覽頁
                },
              );
            },
            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.08)),
            itemCount: files.length,
          );
        },
      ),
    );
  }
}


