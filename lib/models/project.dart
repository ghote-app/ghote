// Project model represents a logical container for study materials.
// It supports collaboration (Pro only) and basic categorization.

class Project {
  final String id;
  final String title;
  final String? description;
  final String ownerId;
  final List<String> collaboratorIds; // Pro only feature
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String status; // 'Active', 'Completed', 'Archived'
  final String? category;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.collaboratorIds,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.status,
    required this.category,
  });

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerId,
    List<String>? collaboratorIds,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? status,
    String? category,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ownerId': ownerId,
      'collaboratorIds': collaboratorIds,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'status': status,
      'category': category,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      collaboratorIds: (json['collaboratorIds'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          <String>[],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      status: json['status'] as String,
      category: json['category'] as String?,
    );
  }
}


