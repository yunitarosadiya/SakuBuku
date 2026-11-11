# DEVELOPMENT PLAN & TASK BREAKDOWN: SAKUBUKU MOBILE APP
## Panduan Pelaksanaan Teknis, Work Breakdown Structure (WBS), dan Task Board Eksekusi

---

**Informasi Proyek:**
- **Nama Aplikasi:** SakuBuku (Pencatatan Keuangan Pribadi & UMKM Offline-First)
- **ID Paket / Bundle ID:** `com.sakubuku.app`
- **Framework & SDK:** Flutter 3.29.3 • Dart 3.7.2
- **Arsitektur:** Feature-First Clean Architecture + Riverpod 2.x
- **Target OS:** Android (minSdkVersion: 21, targetSdkVersion: 34), iOS (13+)
- **Dokumen Referensi:**
  1. [`Blueprint Aplikasi SakuBuku.md.odt`](file:///d:/SakuBuku/Blueprint%20Aplikasi%20SakuBuku.md.odt)
  2. [`Analisis Gap Kompresi Struk Mobile.odt`](file:///d:/SakuBuku/Analisis%20Gap%20Kompresi%20Struk%20Mobile.odt)
  3. [`Rencana_Kerja_Pengembangan_SakuBuku.md`](file:///d:/SakuBuku/Rencana_Kerja_Pengembangan_SakuBuku.md)

---

## 1. STRATEGI IMPLEMENTASI & TARGET MVP

Tujuan pengembangan tahap awal adalah mewujudkan **Minimum Viable Product (MVP)** yang stabil dan siap pakai, dengan fokus keunggulan pada **efisiensi memori & penyimpanan kompresi nota** yang terbukti kebal dari crash *Out-of-Memory (OOM)* pada ponsel *entry-level*.

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                               TARGET MVP SAKUBUKU (V1.0)                              │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ 1. 100% Offline-First (Berjalan instan tanpa internet & tanpa login/akun).           │
│ 2. Pencatatan Transaksi Pemasukan & Pengeluaran dengan Custom Rupiah Keypad.         │
│ 3. Digitalisasi Bukti Nota (Kamera + Crop ROI + Kompresi WebP/JPEG Ukuran 50-110 KB). │
│ 4. Zero-OOM Pipeline (Maks. penggunaan memori Heap < 85 MB saat memproses foto).      │
│ 5. Dashboard Finansial, Riwayat Multi-Filter, Grafik Analisis (fl_chart), & Kalender. │
│ 6. Manajemen Penyimpanan (Storage Info MB) & Pencadangan Data (Ekspor CSV & ZIP).     │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. SPESIFIKASI DEPENDENSI RESMI (`pubspec.yaml`)

Berikut adalah matriks dependensi terverifikasi yang kompatibel dengan Flutter 3.29+ / Dart 3.7+:

```yaml
name: sakubuku
description: "Aplikasi Pencatatan Keuangan Offline-First dengan Kompresi Struk Aman-Memori"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.7.0
  flutter: ">=3.29.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management & Dependency Injection
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Local Database Engine (Isar NoSQL Fast Local DB)
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.5

  # Image Pipeline & Memory-Safe Compression
  image_picker: ^1.1.2
  image_cropper: ^9.0.0
  flutter_image_compress: ^2.4.0

  # Charts & Calendar UI
  fl_chart: ^0.70.2
  table_calendar: ^3.1.3

  # Typography & Iconography
  google_fonts: ^6.2.1
  intl: ^0.20.2
  uuid: ^4.5.1

  # Data Backup, Export & Share
  archive: ^4.0.2
  csv: ^6.0.0
  share_plus: ^10.1.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.15
  isar_generator: ^3.1.0+1
  riverpod_generator: ^2.6.4
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
```

---

## 3. STRUKTUR DIREKTORI PROYEK (FEATURE-FIRST CLEAN ARCHITECTURE)

Struktur folder dirancang terisolasi per fitur (*Feature-First*) agar kode mudah dirawat, diskalakan, dan diuji secara independen:

```
d:/SakuBuku/
├── android/                         # Konfigurasi native Android (minSdk 21, permissions)
├── ios/                             # Konfigurasi native iOS (Camera & Photo permissions)
├── assets/
│   ├── icons/                       # Ikon kategori keuangan SVG/PNG
│   └── images/                      # Ilustrasi kosong (empty states)
├── lib/
│   ├── core/                        # Modul bersama (Shared Kernel)
│   │   ├── constants/               # Warna, ukuran, kategori bawaan
│   │   │   ├── app_colors.dart
│   │   │   ├── app_constants.dart
│   │   │   └── default_categories.dart
│   │   ├── errors/                  # Custom exceptions & failures
│   │   ├── services/                # Low-level Native & Device Services
│   │   │   ├── image_compression_service.dart   # Engine WebP/JPEG aman OOM
│   │   │   ├── receipt_storage_service.dart     # Manajemen sandbox berkas nota
│   │   │   ├── garbage_cleaner_service.dart     # Auto-clean cache/temp
│   │   │   └── backup_restore_service.dart      # Ekspor/Impor CSV & ZIP
│   │   ├── theme/                   # Material 3 Dark & Light theme
│   │   │   └── app_theme.dart
│   │   └── utils/                   # Formatter mata uang & tanggal
│   │       ├── currency_formatter.dart
│   │       └── date_formatter.dart
│   ├── features/                    # Modul per Fitur Fungsional
│   │   ├── splash/                  # Screen 1: Splash & Local DB Init
│   │   ├── dashboard/               # Screen 2: Kartu Saldo, Mini Trend, List Hari Ini
│   │   ├── transactions/            # Screen 3 & 5: Input Form, Keypad, Riwayat & Filter
│   │   │   ├── data/
│   │   │   │   ├── models/transaction_model.dart (Isar schema)
│   │   │   │   └── repositories/transaction_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── usecases/transaction_usecases.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/transaction_controller.dart
│   │   │       ├── screens/transaction_input_screen.dart
│   │   │       ├── screens/transaction_history_screen.dart
│   │   │       └── widgets/numeric_keypad.dart
│   │   ├── receipts/                # Screen 4: Alur Kamera, Cropper, & Pratinjau Nota
│   │   │   ├── presentation/
│   │   │   │   ├── screens/camera_crop_screen.dart
│   │   │   │   └── widgets/receipt_viewer_dialog.dart
│   │   ├── analytics/               # Screen 6: Visualisasi Donut & Bar Charts
│   │   │   └── presentation/screens/analytics_screen.dart
│   │   ├── settings/                # Screen 7: Profil, Tema, Storage Info, Backup
│   │   │   └── presentation/screens/settings_screen.dart
│   │   └── calendar/                # Screen 8: Kalender Interaktif & Transaksi Harian
│   │       └── presentation/screens/calendar_screen.dart
│   ├── app.dart                     # MaterialApp entrypoint
│   └── main.dart                    # Inisialisasi Isar & runApp
└── test/                            # Unit & Widget Test suites
```

---

## 4. TASK BREAKDOWN & JIRA-STYLE BACKLOG

Berikut adalah rincian tugas terstruktur yang dibagi dalam **5 Milestone / Sprint**. Setiap tugas memiliki ID unik, estimasi waktu, prioritas, kriteria keberhasilan (*Definition of Done*), dan panduan teknis implementasi.

### SPRINT 1: INITIATION, ARCHITECTURE, & CORE FINANCIAL ENGINE (Pekan 1 - 2)

#### [TASK-001] Inisialisasi Proyek Flutter & Konfigurasi Lingkungan
- **Kategori:** Project Scaffolding
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 4 Jam
- **Deskripsi:** Membuat proyek Flutter dengan bundle ID `com.sakubuku.app`, membersihkan boilerplate `counter app`, dan mengonfigurasi `.gitignore`.
- **Definition of Done (DoD):**
  - Proyek terkompilasi sukses di Android emulator/device (`flutter run`).
  - File `.gitignore` mengabaikan berkas build, cache, dan file lokal generator.
  - Perintah `flutter analyze` menghasilkan nol *error/warning*.

#### [TASK-002] Konfigurasi Dependensi & Setup Build Runner
- **Kategori:** Architecture
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 3 Jam
- **Deskripsi:** Memasang dependensi inti pada `pubspec.yaml` (Riverpod, Isar, Path Provider, Google Fonts, Intl, FL Chart).
- **Definition of Done (DoD):**
  - `flutter pub get` selesai tanpa konflik dependensi.
  - Skrip generator `dart run build_runner build` berjalan sukses.

#### [TASK-003] Implementasi Design System & AppTheme (Material 3)
- **Kategori:** UI/UX Foundation
- **Prioritas:** `P1 (High)` | **Estimasi:** 6 Jam
- **Deskripsi:** Membuat modul `AppColors` dan `AppTheme` dengan dukungan Light Mode & Dark Mode.
  - Warna Hijau Pemasukan: `#10B981` (Emerald)
  - Warna Merah Pengeluaran: `#EF4444` (Rose Red)
  - Warna Primer SakuBuku: `#2563EB` (Royal Blue) / `#0F172A` (Slate Dark)
  - Font: Google Fonts *Plus Jakarta Sans* atau *Inter*.
- **Definition of Done (DoD):**
  - Komponen Typography, ButtonStyle, CardTheme, dan InputTheme terdefinisi konsisten.
  - Toggle pergantian tema terang/gelap berfungsi mulus.

#### [TASK-004] Skema Isar Database & Repository CRUD Transaksi
- **Kategori:** Local Database
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 8 Jam
- **Deskripsi:** Mendefinisikan entity `@collection class TransactionRecord` dan `@collection class AppPreference`. Membuat antarmuka `TransactionRepository` dan implementasinya menggunakan Isar API.
- **Definition of Done (DoD):**
  - File `transaction_record.g.dart` ter-generate otomatis.
  - Operasi Create, Read, Update, Delete transaksi teruji via unit test.
  - Indexing aktif pada kolom `type`, `date`, `category`, dan `amount`.

#### [TASK-005] Riverpod State Management untuk Transaksi Keuangan
- **Kategori:** State Management
- **Prioritas:** `P1 (High)` | **Estimasi:** 6 Jam
- **Deskripsi:** Membuat Riverpod Notifier untuk mengelola daftar transaksi, kalkulasi sisa saldo, total pemasukan, dan total pengeluaran bulan berjalan.
- **Definition of Done (DoD):**
  - State otomatis ter-update saat transaksi ditambah, diedit, atau dihapus.
  - Kalkulasi finansial presisi tanpa *floating-point rounding error*.

---

### SPRINT 2: MEMORY-SAFE IMAGE COMPRESSION & STORAGE ENGINE (Pekan 3 - 4)

#### [TASK-006] Restrained Camera Capture Service (Anti-OOM Ingestion)
- **Kategori:** Image Processing & Native Safety
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 6 Jam
- **Deskripsi:** Membangun *wrapper* `image_picker` yang membatasi resolusi gambar kamera pada `1920x1080` dan `imageQuality: 85`. Hal ini mencegah Android mengalokasikan Bitmap mentah di atas 25 MB di Native Heap.
- **Definition of Done (DoD):**
  - Foto kamera resolusi tinggi otomatis di-downsample saat ingestion awal.
  - Alokasi Native Heap Android terbukti berada di bawah 30 MB pada profiler.

#### [TASK-007] Integrasi Image Cropper (Mandatory ROI Selection)
- **Kategori:** Image Processing & UI
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 6 Jam
- **Deskripsi:** Mengintegrasikan `image_cropper` dengan preset rasio aspek dokumen struk. Menghadirkan panduan visual agar pengguna memotong latar meja (NROI) sebelum berkas diproses kompresi.
- **Definition of Done (DoD):**
  - Antarmuka cropping muncul mulus setelah foto diambil.
  - Hasil cropping hanya memuat area kertas struk.

#### [TASK-008] Adaptive Image Compression Engine (WebP QF 75 & JPEG QF 72)
- **Kategori:** Core Feature & Research Gap Mitigation
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 8 Jam
- **Deskripsi:** Mengimplementasikan `ImageCompressionService` dengan parameter:
  - Format Primer: `CompressFormat.webp` (Quality: 75).
  - Fallback Format: `CompressFormat.jpeg` (Quality: 72, subsampling 4:2:0).
  - Target Lebar: Minimal 1080 piksel (mempertahankan kerapatan >= 300 DPI pada struk 80mm).
- **Definition of Done (DoD):**
  - File foto struk 3-5 MB menyusut menjadi **50 KB - 110 KB** (>96% kompresi).
  - Teks font 7-8pt pada struk tetap tajam dan terbaca jelas pada zoom 200%.

#### [TASK-009] Sandbox Storage Management & Auto-Garbage Cleaner
- **Kategori:** File System & Maintenance
- **Prioritas:** `P1 (High)` | **Estimasi:** 4 Jam
- **Deskripsi:** Mengatur penyimpanan berkas nota permanen di direktori sandbox aplikasi (`path_provider`). Membangun service otomatis untuk membersihkan file cache temporer di `/cache` dan `/tmp` pasca kompresi.
- **Definition of Done (DoD):**
  - File nota tersimpan di folder aman aplikasi dengan nama acak UUID (`.webp`).
  - Folder cache temporer bersih dari sisa berkas *image_picker* dan *cropper*.

---

### SPRINT 3: IMPLEMENTASI UI UTAMA (DASHBOARD, INPUT, & RIWAYAT) (Pekan 5 - 6)

#### [TASK-010] Screen 1: Splash Screen & Background Initialization
- **Kategori:** UI Screen
- **Prioritas:** `P1 (High)` | **Estimasi:** 4 Jam
- **Deskripsi:** Menampilkan logo SakuBuku, memuat Isar database di background thread, memeriksa hak akses storage, dan navigasi otomatis ke Dashboard dalam 1.2 detik.
- **Definition of Done (DoD):**
  - Tidak ada *blank screen* saat aplikasi dibuka pertama kali (*cold start* < 1 detik).

#### [TASK-011] Screen 2: Home / Dashboard Screen
- **Kategori:** UI Screen
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 8 Jam
- **Deskripsi:** Membangun Dashboard pusat:
  - Header sapaan personal ("Halo, [Nama]!").
  - Kartu Saldo Utama (Sisa Saldo, Total Pemasukan Bulan Ini, Total Pengeluaran Bulan Ini).
  - Grafik Mini Trend 7 Hari (`fl_chart` sparkline).
  - Daftar Transaksi Hari Ini (dengan state kosong / ilustrasi menarik).
  - Floating Action Button (FAB) mencolok untuk input kilat.
- **Definition of Done (DoD):**
  - Seluruh angka saldo reaktif terhadap perubahan data.
  - Grafik mini merender tren pengeluaran harian dengan presisi.

#### [TASK-012] Screen 3: Layar Input Transaksi & Custom Numeric Keypad
- **Kategori:** UI Screen & Interaction
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 10 Jam
- **Deskripsi:** Membangun form penambahan transaksi:
  - Toggle Pemasukan (Hijau) / Pengeluaran (Merah).
  - Custom Numeric Keypad Rupiah yang cepat digunakan dengan satu tangan.
  - Grid pemilihan ikon kategori.
  - Tombol integrasi lampiran nota (mengarah ke alur Kamera/Cropper).
  - Pratinjau thumbnail nota terlampir dengan opsi hapus/ganti.
- **Definition of Done (DoD):**
  - Form input merespons sentuhan tanpa *lag*.
  - Nominal terformat otomatis ke Rupiah (`Rp 50.000`).
  - Transaksi tersimpan ke Isar beserta path foto nota terkompresi.

#### [TASK-013] Screen 5: Riwayat Transaksi & Sistem Filter Interaktif
- **Kategori:** UI Screen
- **Prioritas:** `P1 (High)` | **Estimasi:** 8 Jam
- **Deskripsi:** Menampilkan daftar memanjang seluruh transaksi dengan *Sticky Date Headers*. Menyediakan filter berdasarkan bulan, rentang tanggal, dan tipe (Semua / Pemasukan / Pengeluaran).
- **Definition of Done (DoD):**
  - Menampilkan ikon klip kertas pada item yang memiliki bukti nota.
  - Mengetuk item membuka mode Edit / Hapus.
  - Mengetuk ikon klip membuka modal pratinjau foto nota secara instan.

---

### SPRINT 4: ANALISIS GRAFIK, KALENDER, & PENGATURAN BACKUP (Pekan 7 - 8)

#### [TASK-014] Screen 6: Analisis Visual & Grafik Finansial
- **Kategori:** UI Screen & Data Visualization
- **Prioritas:** `P1 (High)` | **Estimasi:** 8 Jam
- **Deskripsi:** Membangun visualisasi interaktif menggunakan `fl_chart`:
  - Donut Chart pengeluaran berdasarkan kategori.
  - Bar Chart komparasi bulanan Pemasukan vs Pengeluaran.
  - Kartu ringkasan: Rata-rata pengeluaran harian & kategori pengeluaran terbesar.
- **Definition of Done (DoD):**
  - Grafik interaktif saat disentuh (menampilkan persentase & tooltip nominal).

#### [TASK-015] Screen 8: Kalender Finansial Transaksi
- **Kategori:** UI Screen
- **Prioritas:** `P2 (Medium)` | **Estimasi:** 6 Jam
- **Deskripsi:** Mengintegrasikan `table_calendar` dengan penanda titik (*dot indicator*) berwarna hijau (pemasukan) dan merah (pengeluaran). Menampilkan daftar transaksi pada tanggal terpilih di panel bawah.
- **Definition of Done (DoD):**
  - Tanggal dengan transaksi memiliki dot penanda yang akurat.
  - Klik tanggal memfilter daftar transaksi di bawahnya secara instan.

#### [TASK-016] Screen 7: Pengaturan, Profil, & Widget Penggunaan Memori
- **Kategori:** UI Screen
- **Prioritas:** `P1 (High)` | **Estimasi:** 6 Jam
- **Deskripsi:** Membangun layar pengaturan preferensi:
  - Input nama panggilan profil.
  - Sakelar Tema Gelap / Terang (*Dark/Light Mode*).
  - **Widget Info Penyimpanan:** Menghitung dan menampilkan total MegaByte (MB) yang digunakan oleh Database dan Berkas Foto Nota.
- **Definition of Done (DoD):**
  - Ukuran memori terhitung presisi dalam satuan KB/MB secara *real-time*.

#### [TASK-017] Modul Pencadangan & Pemulihan Data (Ekspor CSV & ZIP Archive)
- **Kategori:** Core Utility & Data Safety
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 8 Jam
- **Deskripsi:** Membangun fitur pencadangan data mandiri:
  - Ekspor seluruh tabel transaksi ke berkas lembar kerja CSV.
  - Fitur Full Backup: Mengemas basis data Isar + seluruh folder foto nota menjadi berkas arsip ZIP `.sakubuku`.
  - Fitur Restore: Mengekstrak arsip cadangan dan memulihkan basis data serta berkas nota ke direktori aplikasi.
- **Definition of Done (DoD):**
  - Ekspor CSV dapat dibuka rapi di Microsoft Excel / Google Sheets.
  - Proses pencadangan dan pemulihan arsip ZIP berhasil memulihkan 100% data transaksi dan foto nota.

---

### SPRINT 5: BENCHMARKING, STRESS-TESTING MEMORI, & HARDENING (Pekan 9 - 10)

#### [TASK-018] Memory Stress-Testing pada Perangkat Android Low-End
- **Kategori:** Quality Assurance & Performance
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 6 Jam
- **Deskripsi:** Menguji aplikasi pada ponsel fisik atau emulator dengan spesifikasi rendah (RAM 2 GB, Android 9-11). Menjalankan skenario pengambilan dan kompresi 20 foto nota berturut-turut.
- **Definition of Done (DoD):**
  - **Zero OOM Crash:** Tidak terjadi crash memori sepanjang sesi pengujian.
  - Alokasi Native Heap selalu kembali normal pasca proses kompresi (*no memory leaks*).

#### [TASK-019] Benchmarking Kualitas Citra Struk (DPI & Keterbacaan)
- **Kategori:** Quality Assurance & Research Validation
- **Prioritas:** `P1 (High)` | **Estimasi:** 6 Jam
- **Deskripsi:** Menguji 50 sampel struk belanja fisik Indonesia (kertas termal pudar, noda, struk mini market). Mengukur ukuran berkas akhir dan menguji keterbacaan teks nominal.
- **Definition of Done (DoD):**
  - Ukuran berkas rata-rata berada pada rentang **50 KB - 110 KB**.
  - Teks struk 100% terbaca jelas oleh mata manusia pada perbesaran normal.

#### [TASK-020] Release Hardening, ProGuard/R8, & Final APK Packaging
- **Kategori:** Deployment & Release
- **Prioritas:** `P0 (Blocker)` | **Estimasi:** 4 Jam
- **Deskripsi:** Mengonfigurasi ProGuard dan R8 rules untuk Android, mengaktifkan `shrinkResources` dan `minifyEnabled`. Mengemas build rilis produksi (APK & AAB).
- **Definition of Done (DoD):**
  - Ukuran unduhan APK rilis di bawah 20 MB.
  - Aplikasi rilis berjalan stabil tanpa *missing symbol errors*.

---

## 5. PANDUAN LANGKAH MEMULAI HARI INI (KICKOFF EXECUTION GUIDE)

Berikut adalah instruksi baris perintah (*step-by-step commands*) untuk menginisialisasi proyek SakuBuku secara langsung di workspace `d:/SakuBuku`:

### Langkah 1: Inisialisasi Proyek Flutter
Jalankan perintah berikut di terminal PowerShell:
```powershell
# Inisialisasi proyek Flutter langsung pada direktori d:/SakuBuku
cd d:\SakuBuku
flutter create --org com.sakubuku --project-name sakubuku --platforms android,ios .
```

### Langkah 2: Memasang Seluruh Paket Dependensi
Tambahkan dependensi yang telah dispesifikasikan:
```powershell
flutter pub add flutter_riverpod riverpod_annotation isar isar_flutter_libs path_provider image_picker image_cropper flutter_image_compress fl_chart table_calendar google_fonts intl uuid archive csv share_plus
flutter pub add --dev build_runner isar_generator riverpod_generator mocktail
```

### Langkah 3: Membuat Struktur Folder Lengkap
Jalankan skrip PowerShell untuk membuat kerangka folder Feature-First:
```powershell
New-Item -ItemType Directory -Force -Path `
  "lib/core/constants", `
  "lib/core/errors", `
  "lib/core/services", `
  "lib/core/theme", `
  "lib/core/utils", `
  "lib/features/splash/presentation", `
  "lib/features/dashboard/presentation/widgets", `
  "lib/features/transactions/data/models", `
  "lib/features/transactions/data/repositories", `
  "lib/features/transactions/domain/usecases", `
  "lib/features/transactions/presentation/controllers", `
  "lib/features/transactions/presentation/screens", `
  "lib/features/transactions/presentation/widgets", `
  "lib/features/receipts/presentation/screens", `
  "lib/features/receipts/presentation/widgets", `
  "lib/features/analytics/presentation/screens", `
  "lib/features/settings/presentation/screens", `
  "lib/features/calendar/presentation/screens", `
  "assets/icons", `
  "assets/images"
```

### Langkah 4: Konfigurasi Izin Native Android (`AndroidManifest.xml`)
Tambahkan izin kamera dan baca galeri pada file `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Izin Kamera dan Galeri -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

    <!-- Activity konfigurasi UCrop untuk image_cropper -->
    <application>
        ...
        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
    </application>
</manifest>
```

---

## 6. CHECKLIST PELACAKAN KEMAJUAN (INTERACTIVE PROGRESS TRACKER)

Gunakan daftar periksa (*checklist*) ini untuk memantau status penyelesaian setiap tugas harian:

### Inisiasi & Arsitektur Inti (Sprint 1)
- [ ] **[TASK-001]** Inisialisasi Proyek Flutter & Verifikasi Kompilasi Bersih
- [ ] **[TASK-002]** Instalasi Dependensi & Verifikasi Build Runner
- [ ] **[TASK-003]** Implementasi Design System & AppTheme (Material 3 Dark/Light)
- [ ] **[TASK-004]** Pembuatan Skema Isar Database & Repository CRUD Transaksi
- [ ] **[TASK-005]** Implementasi Riverpod State Notifiers (Saldo, Transaksi, Agregasi)

### Pipeline Citra & Kompresi Aman-Memori (Sprint 2)
- [ ] **[TASK-006]** Pembuatan Service Kamera Beresolusi Dibatasi (Anti-OOM)
- [ ] **[TASK-007]** Integrasi Image Cropper untuk Seleksi Area Struk (Mandatory ROI)
- [ ] **[TASK-008]** Pembuatan Engine Kompresi WebP QF 75 & Fallback JPEG QF 72
- [ ] **[TASK-009]** Setup Sandbox Storage & Pembersih Otomatis File Cache Temporer

### Antarmuka Pengguna & Interaksi (Sprint 3)
- [ ] **[TASK-010]** Screen 1: Splash Screen & Inisialisasi Isar di Latar Belakang
- [ ] **[TASK-011]** Screen 2: Dashboard Saldo, Mini Trend Chart, & Daftar Hari Ini
- [ ] **[TASK-012]** Screen 3: Layar Input Transaksi, Numeric Keypad, & Lampiran Nota
- [ ] **[TASK-013]** Screen 5: Riwayat Transaksi, Multi-Filter, & Modal Viewer Nota

### Analisis, Kalender, & Pencadangan Data (Sprint 4)
- [ ] **[TASK-014]** Screen 6: Layar Analisis Grafik Interaktif (Donut & Bar Charts)
- [ ] **[TASK-015]** Screen 8: Kalender Transaksi dengan Titik Penanda Warna
- [ ] **[TASK-016]** Screen 7: Layar Pengaturan, Dark Mode, & Widget Info Memori (MB)
- [ ] **[TASK-017]** Engine Ekspor Transaksi ke CSV & Full Backup/Restore Arsip ZIP

### Pengujian Kualitas, Benchmarking, & Rilis (Sprint 5)
- [ ] **[TASK-018]** Memory Stress Testing pada Android RAM 2 GB (Verifikasi Zero-OOM)
- [ ] **[TASK-019]** Benchmarking Ukuran Berkas (Target 50-110 KB) & Keterbacaan Teks
- [ ] **[TASK-020]** Release Hardening (ProGuard/R8, Minify) & Packaging Final APK/AAB

---
*Dokumen ini merupakan panduan operasional teknis pengembangan resmi untuk aplikasi SakuBuku.*
