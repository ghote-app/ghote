import 'package:flutter/material.dart';

/// Represents a project item in the dashboard grid
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
    this.colorTag,
    this.description,
  });
  
  final String id;
  final String title;
  final String status;
  final int documentCount;
  final String lastUpdated;
  final String image;
  final double progress;
  final String category;
  final String? colorTag;
  final String? description;
}
