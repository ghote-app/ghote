import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/file_model.dart';

class StorageService {
  const StorageService();

  Future<String> saveToLocal(File file, String projectId) async {
    final directory = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${directory.path}/ghote/$projectId');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    final fileName = file.path.split('/').last;
    final localPath = '${projectDir.path}/$fileName';
    await file.copy(localPath);
    return localPath;
  }

  Future<Map<String, String>> uploadToCloudflare({
    required File file,
    required String projectId,
    required String userId,
  }) async {
    // Feature flag: dev uses Firebase Storage, release uses Cloudflare R2
    if (!kReleaseMode) {
      final ref = FirebaseStorage.instance.ref().child('files/$userId/$projectId/${file.path.split('/').last}');
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      return {
        'cloudPath': ref.fullPath,
        'downloadUrl': url,
      };
    }

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http.post(
      Uri.parse('https://your-api.example.com/api/upload/presigned-url'),
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'fileName': file.path.split('/').last,
        'projectId': projectId,
        'userId': userId,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to get presigned url: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final presignedUrl = data['uploadUrl'] as String;
    final cloudPath = data['path'] as String;

    final putRes = await http.put(
      Uri.parse(presignedUrl),
      body: await file.readAsBytes(),
    );
    if (putRes.statusCode >= 400) {
      throw Exception('Upload to Cloudflare failed: ${putRes.statusCode}');
    }

    return {
      'cloudPath': cloudPath,
      'downloadUrl': data['downloadUrl'] as String,
    };
  }

  Future<Uint8List> getFileContent(FileModel file) async {
    if (file.storageType == 'local') {
      return await File(file.localPath!).readAsBytes();
    }
    final res = await http.get(Uri.parse(file.downloadUrl!));
    if (res.statusCode >= 400) {
      throw Exception('Failed to download file: ${res.statusCode}');
    }
    return res.bodyBytes;
  }
}


