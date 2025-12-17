import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/file_model.dart';
import 'storage_service.dart';
import 'gemini_service.dart';

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

      // 使用 Syncfusion PDF 套件提取文字
      final syncfusion_pdf.PdfDocument document = syncfusion_pdf.PdfDocument(inputBytes: fileBytes);
      
      final StringBuffer extractedText = StringBuffer();
      
      // 遍歷所有頁面
      for (int i = 0; i < document.pages.count; i++) {
        // 使用 PdfTextExtractor 提取文字
        final String pageText = syncfusion_pdf.PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        
        if (pageText.isNotEmpty) {
          extractedText.writeln('--- 第 ${i + 1} 頁 ---');
          extractedText.writeln(pageText.trim());
          extractedText.writeln('');
        }
      }
      
      // 釋放資源
      document.dispose();
      
      final result = extractedText.toString().trim();
      
      if (result.isEmpty) {
        throw Exception(
          'PDF 中沒有找到可提取的文字。\n\n'
          '可能原因：\n'
          '1. 這是掃描版 PDF（圖片型）\n'
          '2. PDF 包含大量圖表或圖片\n\n'
          '解決方案：\n'
          '• 在 AI 聊天時，可直接將 PDF 檔案中的圖片上傳並詢問 AI\n'
          '• 或使用 OCR 工具將 PDF 轉換為可編輯文字'
        );
      }
      
      return result;
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
        final text = String.fromCharCodes(fileBytes);
        // 驗證是否為有效文字（檢查是否包含過多不可見字符）
        if (text.trim().isEmpty) {
          throw Exception('文件內容為空');
        }
        return text;
      } catch (e) {
        // 如果解碼失敗，嘗試移除無效字符
        final cleanedBytes = fileBytes.where((byte) => byte >= 32 || byte == 9 || byte == 10 || byte == 13).toList();
        final text = String.fromCharCodes(cleanedBytes);
        if (text.trim().isEmpty) {
          throw Exception('無法解析文件內容，可能不是有效的文字檔案');
        }
        return text;
      }
    } catch (e) {
      throw Exception('TXT 文字提取失敗: $e');
    }
  }

  /// 使用 OCR 提取圖片中的文字
  Future<String> extractImageText(FileModel file) async {
    File? tempFile;
    TextRecognizer? textRecognizer;
    
    try {
      final storage = const StorageService();
      File imageFile;

      // 獲取圖片文件
      if (file.storageType == 'local' && file.localPath != null) {
        imageFile = File(file.localPath!);
        if (!await imageFile.exists()) {
          throw Exception('圖片檔案不存在');
        }
      } else if (file.storageType == 'cloud' && file.downloadUrl != null) {
        // 下載雲端圖片到臨時文件
        final bytes = await storage.getFileContent(file);
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.${file.type}';
        imageFile = File(tempPath);
        await imageFile.writeAsBytes(bytes);
        tempFile = imageFile; // 記錄臨時文件以便清理
      } else {
        throw Exception('無法讀取圖片檔案');
      }

      // 使用 Google ML Kit 進行 OCR
      final inputImage = InputImage.fromFile(imageFile);
      // 使用預設的文字識別器（支援多種語言包括中文）
      textRecognizer = TextRecognizer();
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final StringBuffer extractedText = StringBuffer();
      
      // 組織提取的文字
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText.writeln(line.text);
        }
      }
      
      final result = extractedText.toString().trim();
      
      if (result.isEmpty) {
        throw Exception('圖片中沒有找到可識別的文字');
      }
      
      return result;
    } catch (e) {
      throw Exception('OCR 文字提取失敗: $e');
    } finally {
      // 確保資源被釋放
      try {
        textRecognizer?.close();
      } catch (e) {
        print('關閉 OCR 識別器失敗: $e');
      }
      
      // 清理臨時文件
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          print('刪除臨時文件失敗: $e');
        }
      }
    }
  }

  /// 提取 DOCX 文件的文字內容
  Future<String> extractDocxText(FileModel file) async {
    File? tempFile;
    
    try {
      final storage = const StorageService();
      File docxFile;

      // 獲取 DOCX 文件
      if (file.storageType == 'local' && file.localPath != null) {
        docxFile = File(file.localPath!);
        if (!await docxFile.exists()) {
          throw Exception('DOCX 檔案不存在');
        }
      } else if (file.storageType == 'cloud' && file.downloadUrl != null) {
        // 下載雲端文件到臨時文件
        final bytes = await storage.getFileContent(file);
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.docx';
        docxFile = File(tempPath);
        await docxFile.writeAsBytes(bytes);
        tempFile = docxFile; // 記錄臨時文件以便清理
      } else {
        throw Exception('無法讀取 DOCX 檔案');
      }

      // 讀取 DOCX 文件內容
      final bytes = await docxFile.readAsBytes();
      
      // 使用 docx_to_text 提取文字
      final text = docxToText(bytes);
      
      if (text.trim().isEmpty) {
        throw Exception('DOCX 文件中沒有找到可提取的文字');
      }
      
      return text.trim();
    } catch (e) {
      throw Exception('DOCX 文字提取失敗: $e');
    } finally {
      // 清理臨時文件
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          print('刪除臨時 DOCX 文件失敗: $e');
        }
      }
    }
  }

  /// 使用 OCR 提取掃描版 PDF 中的文字
  Future<String> extractScannedPdfText(FileModel file) async {
    try {
      // 注意：完整的掃描 PDF OCR 需要將 PDF 轉為圖片然後 OCR
      // 這裡提供一個簡化版本的提示
      throw Exception(
        '掃描版 PDF 處理需要先將 PDF 轉換為圖片。\n'
        '建議：\n'
        '1. 使用線上工具將 PDF 轉為圖片\n'
        '2. 然後上傳圖片使用 OCR 功能'
      );
    } catch (e) {
      throw Exception('掃描版 PDF 處理失敗: $e');
    }
  }

  /// 提取音訊文件的文字內容（使用 Gemini AI）
  Future<String> extractAudioText(FileModel file) async {
    try {
      final storage = const StorageService();
      Uint8List audioBytes;

      // 獲取音訊文件
      if (file.storageType == 'local' && file.localPath != null) {
        final localFile = File(file.localPath!);
        if (!await localFile.exists()) {
          throw Exception('音訊檔案不存在');
        }
        audioBytes = await localFile.readAsBytes();
      } else if (file.storageType == 'cloud' && file.downloadUrl != null) {
        audioBytes = await storage.getFileContent(file);
      } else {
        throw Exception('無法讀取音訊檔案');
      }

      // 使用 Gemini AI 進行語音轉文字
      final geminiService = GeminiService();
      
      // 準備音訊數據
      final audioPart = DataPart('audio/${file.type}', audioBytes);
      
      final text = await geminiService.generateText(
        prompt: '請將這段音訊轉換為文字。只返回轉錄的文字內容，不要添加任何說明或註解。',
        audioPart: audioPart,
      );
      
      if (text.trim().isEmpty) {
        throw Exception('音訊轉文字失敗：無法識別音訊內容');
      }
      
      return text.trim();
    } catch (e) {
      throw Exception('音訊文字提取失敗: $e');
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
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'bmp':
      case 'gif':
        return await extractImageText(file);
      case 'docx':
        return await extractDocxText(file);
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'aac':
      case 'm4a':
      case 'wma':
        return await extractAudioText(file);
      case 'doc':
        throw Exception(
          'DOC 格式（舊版 Word）暫不支援。\n'
          '建議：\n'
          '1. 將 DOC 文件另存為 DOCX 格式\n'
          '2. 或將 Word 文件另存為 PDF\n'
          '3. 或複製內容到 TXT 文件後上傳'
        );
      default:
        throw Exception('不支援的文件類型: $fileType\n支援格式：PDF, DOCX, TXT, JPG, PNG, MP3, WAV, M4A 等音訊格式');
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
    String status, // 'pending' | 'processing' | 'extracted' | 'failed'
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

