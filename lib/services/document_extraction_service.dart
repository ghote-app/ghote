import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/file_model.dart';
import '../services/storage_service.dart';

class DocumentExtractionService {
  const DocumentExtractionService();

  /// 提取 PDF 文件的文字內容
  Future<String> extractPdfText(FileModel file) async {
    try {
      final storage = const StorageService();
      Uint8List fileBytes;

      // 獲取文件內容
      if (file.storageType == 'local' && file.localPath != null) {
        final localFile = File(file.localPath!);
        if (!await localFile.exists()) {
          throw Exception('檔案不存在');
        }
        fileBytes = await localFile.readAsBytes();
      } else if (file.storageType == 'cloud' && file.downloadUrl != null) {
        fileBytes = await storage.getFileContent(file);
      } else {
        throw Exception('無法讀取檔案');
      }

      // 使用 pdf 套件提取文字
      // 注意：pdf 套件主要用於創建 PDF，提取文字功能有限
      // 對於生產環境，建議使用後端服務或 OCR
      // 這裡提供一個基本實現
      try {
        // pdf 套件不直接支持文字提取
        // 暫時返回提示訊息，建議用戶使用其他方法
        throw Exception('PDF 文字提取需要使用 OCR 或後端服務。請確保 PDF 包含可選文字層。');
      } catch (e) {
        // 如果提取失敗，返回錯誤
        throw Exception('PDF 文字提取失敗: $e');
      }
    } catch (e) {
      throw Exception('PDF 文字提取失敗: $e');
    }
  }

  /// 提取 TXT 文件的文字內容
  Future<String> extractTxtText(FileModel file) async {
    try {
      final storage = const StorageService();
      Uint8List fileBytes;

      if (file.storageType == 'local' && file.localPath != null) {
        final localFile = File(file.localPath!);
        if (!await localFile.exists()) {
          throw Exception('檔案不存在');
        }
        fileBytes = await localFile.readAsBytes();
      } else if (file.storageType == 'cloud' && file.downloadUrl != null) {
        fileBytes = await storage.getFileContent(file);
      } else {
        throw Exception('無法讀取檔案');
      }

      // 嘗試 UTF-8 解碼
      try {
        return String.fromCharCodes(fileBytes);
      } catch (e) {
        // 如果 UTF-8 失敗，嘗試其他編碼
        return String.fromCharCodes(fileBytes);
      }
    } catch (e) {
      throw Exception('TXT 文字提取失敗: $e');
    }
  }

  /// 提取文件文字（自動判斷類型）
  Future<String> extractText(FileModel file) async {
    final fileType = file.type.toLowerCase();
    
    switch (fileType) {
      case 'pdf':
        return await extractPdfText(file);
      case 'txt':
        return await extractTxtText(file);
      case 'docx':
      case 'doc':
        // DOCX 處理需要額外的套件，暫時返回錯誤
        throw Exception('DOCX 文件處理功能尚未實現');
      default:
        throw Exception('不支援的文件類型: $fileType');
    }
  }

  /// 將提取的文字保存到 Firestore
  Future<void> saveExtractedText(String fileId, String projectId, String text) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('files')
          .doc(fileId)
          .update({
        'extractedText': text,
        'extractionStatus': 'extracted',
      });
    } catch (e) {
      throw Exception('保存提取文字失敗: $e');
    }
  }

  /// 更新提取狀態
  Future<void> updateExtractionStatus(
    String fileId,
    String projectId,
    String status, // 'pending' | 'extracted' | 'failed'
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('files')
          .doc(fileId)
          .update({
        'extractionStatus': status,
      });
    } catch (e) {
      throw Exception('更新提取狀態失敗: $e');
    }
  }
}

