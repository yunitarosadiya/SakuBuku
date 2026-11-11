import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';

class StorageInfo {
  final int databaseSizeBytes;
  final int receiptsSizeBytes;
  final int receiptsCount;

  const StorageInfo({
    required this.databaseSizeBytes,
    required this.receiptsSizeBytes,
    required this.receiptsCount,
  });

  int get totalSizeBytes => databaseSizeBytes + receiptsSizeBytes;

  String get databaseSizeFormatted => formatBytes(databaseSizeBytes);
  String get receiptsSizeFormatted => formatBytes(receiptsSizeBytes);
  String get totalSizeFormatted => formatBytes(totalSizeBytes);

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class StorageService {
  static const String receiptFolder = 'receipts';

  /// Mendapatkan direktori permanen sandbox untuk nota
  static Future<Directory> getReceiptsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, receiptFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Membuat path file unik untuk nota baru
  static Future<String> generateReceiptPath({String extension = '.webp'}) async {
    if (kIsWeb) {
      return 'web_receipt_${const Uuid().v4()}$extension';
    }
    final dir = await getReceiptsDirectory();
    final fileName = '${const Uuid().v4()}$extension';
    return p.join(dir.path, fileName);
  }

  /// Menghitung total pemakaian memori lokal aplikasi (Database + Berkas Nota)
  static Future<StorageInfo> getStorageUsage() async {
    if (kIsWeb) {
      return const StorageInfo(
        databaseSizeBytes: 0,
        receiptsSizeBytes: 0,
        receiptsCount: 0,
      );
    }

    final dbSize = await DatabaseHelper.instance.getDatabaseFileSize();

    int receiptsSize = 0;
    int receiptsCount = 0;

    try {
      final dir = await getReceiptsDirectory();
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final entity in files) {
          if (entity is File) {
            receiptsSize += await entity.length();
            receiptsCount++;
          }
        }
      }
    } catch (_) {}

    return StorageInfo(
      databaseSizeBytes: dbSize,
      receiptsSizeBytes: receiptsSize,
      receiptsCount: receiptsCount,
    );
  }

  /// Menghapus file nota spesifik dari direktori sandbox
  static Future<bool> deleteReceiptFile(String? filePath) async {
    if (kIsWeb || filePath == null || filePath.isEmpty) return false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Auto Garbage Cleaner: Membersihkan file sampah temporary di folder cache
  static Future<int> cleanTemporaryFiles() async {
    if (kIsWeb) return 0;
    int deletedCount = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return deletedCount;
  }
}
