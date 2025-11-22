// FileModel describes a file item within a project and supports
// dual storage backends: local (Free) and cloud (Pro with Cloudflare R2).

class FileModel {
  final String id;
  final String projectId;
  final String name;
  final String type; // 'pdf', 'png', 'txt', 'docx', etc.
  final String category; // 'document', 'image', 'video', 'audio', 'other'
  final int sizeBytes;
  final String storageType; // 'local' | 'cloud'
  final String? localPath;
  final String? cloudPath;
  final String? downloadUrl;
  final String uploaderId;
  final DateTime uploadedAt;
  final Map<String, dynamic>? metadata;
  final String? extractedText; // 提取的文字內容
  final String? extractionStatus; // 'pending' | 'extracted' | 'failed'

  const FileModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    required this.category,
    required this.sizeBytes,
    required this.storageType,
    required this.localPath,
    required this.cloudPath,
    required this.downloadUrl,
    required this.uploaderId,
    required this.uploadedAt,
    required this.metadata,
    this.extractedText,
    this.extractionStatus,
  });

  String get formattedSize {
    const int kb = 1024;
    const int mb = 1024 * 1024;
    if (sizeBytes >= mb) {
      return '${(sizeBytes / mb).toStringAsFixed(2)} MB';
    }
    if (sizeBytes >= kb) {
      return '${(sizeBytes / kb).toStringAsFixed(2)} KB';
    }
    return '$sizeBytes B';
  }

  FileModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? type,
    String? category,
    int? sizeBytes,
    String? storageType,
    String? localPath,
    String? cloudPath,
    String? downloadUrl,
    String? uploaderId,
    DateTime? uploadedAt,
    Map<String, dynamic>? metadata,
    String? extractedText,
    String? extractionStatus,
  }) {
    return FileModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      storageType: storageType ?? this.storageType,
      localPath: localPath ?? this.localPath,
      cloudPath: cloudPath ?? this.cloudPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploaderId: uploaderId ?? this.uploaderId,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      metadata: metadata ?? this.metadata,
      extractedText: extractedText ?? this.extractedText,
      extractionStatus: extractionStatus ?? this.extractionStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'type': type,
      'category': category,
      'sizeBytes': sizeBytes,
      'storageType': storageType,
      'localPath': localPath,
      'cloudPath': cloudPath,
      'downloadUrl': downloadUrl,
      'uploaderId': uploaderId,
      'uploadedAt': uploadedAt.toIso8601String(),
      'metadata': metadata,
      'extractedText': extractedText,
      'extractionStatus': extractionStatus,
    };
  }

  static String _getCategoryFromType(String type) {
    final ext = type.toLowerCase();
    
    // Document types
    if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'].contains(ext)) {
      return 'document';
    }
    
    // Image types
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp', 'ico', 'tiff', 'heic'].contains(ext)) {
      return 'image';
    }
    
    // Video types
    if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm', 'm4v', '3gp'].contains(ext)) {
      return 'video';
    }
    
    // Audio types
    if (['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'].contains(ext)) {
      return 'audio';
    }
    
    return 'other';
  }

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      category: json['category'] as String? ?? _getCategoryFromType(json['type'] as String),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      storageType: json['storageType'] as String,
      localPath: json['localPath'] as String?,
      cloudPath: json['cloudPath'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      uploaderId: json['uploaderId'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      extractedText: json['extractedText'] as String?,
      extractionStatus: json['extractionStatus'] as String?,
    );
  }
}


