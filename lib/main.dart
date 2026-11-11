import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data simbol tanggal bahasa Indonesia untuk pustaka intl
  await initializeDateFormatting('id_ID', null);

  // Konfigurasi Database Factory Universal (Web, Windows Desktop, Android, & iOS)
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Database akan diinisialisasi secara lazy saat pertama kali diakses oleh Riverpod

  runApp(
    const ProviderScope(
      child: SakuBukuApp(),
    ),
  );
}
