import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'storage_service.dart';

class CompressionResult {
  final File file;
  final int sizeBytes;
  final String format;

  const CompressionResult({
    required this.file,
    required this.sizeBytes,
    required this.format,
  });

  String get sizeFormatted => StorageInfo.formatBytes(sizeBytes);
}

class ImageCompressionService {
  /// Kompresi adaptif aman-memori untuk foto nota transaksi.
  /// Menerapkan temuan Analisis Gap:
  /// - WebP Lossy QF 75 untuk preservasi tepi karakter teks nota
  /// - Lebar minimum 1080px untuk menjaga kerapatan >= 300 DPI
  /// - Pembuangan metadata EXIF untuk privasi dan hemat byte
  static Future<CompressionResult?> compressReceipt(File rawFile) async {
    if (kIsWeb) return null;
    try {
      if (!await rawFile.exists()) return null;

      final targetPathWebp = await StorageService.generateReceiptPath(extension: '.webp');

      // 1. Coba kompresi format WebP (sweet spot QF 75)
      var compressedXFile = await FlutterImageCompress.compressAndGetFile(
        rawFile.absolute.path,
        targetPathWebp,
        format: CompressFormat.webp,
        quality: 75,
        minWidth: 1080,
        minHeight: 1440,
        keepExif: false,
      );

      String formatUsed = 'WEBP';

      // 2. Fallback ke JPEG jika WebP tidak didukung perangkat lawas
      if (compressedXFile == null) {
        final targetPathJpeg = targetPathWebp.replaceAll('.webp', '.jpg');
        compressedXFile = await FlutterImageCompress.compressAndGetFile(
          rawFile.absolute.path,
          targetPathJpeg,
          format: CompressFormat.jpeg,
          quality: 72,
          minWidth: 1080,
          minHeight: 1440,
          keepExif: false,
        );
        formatUsed = 'JPEG';
      }

      // 3. Bersihkan file mentah temporer dari kamera/cropper
      try {
        if (await rawFile.exists()) {
          await rawFile.delete();
        }
      } catch (_) {}

      if (compressedXFile != null) {
        final finalFile = File(compressedXFile.path);
        final size = await finalFile.length();
        return CompressionResult(
          file: finalFile,
          sizeBytes: size,
          format: formatUsed,
        );
      }
    } catch (_) {}

    return null;
  }
}
