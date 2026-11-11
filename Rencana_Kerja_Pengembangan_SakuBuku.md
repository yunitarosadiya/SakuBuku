# DOKUMEN RENCANA KERJA PENGEMBANGAN APLIKASI SAKUBUKU
## Arsitektur Offline-First, Rekayasa Kompresi Struk Aman-Memori, dan Roadmap Implementasi Terpadu

---

**Identitas Dokumen:**
- **Nama Dokumen:** Dokumen Analisis Sintesis & Rencana Kerja Pengembangan Aplikasi SakuBuku
- **Versi:** 1.0 (Final Architecture & Execution Blueprint)
- **Status:** Approved for Implementation
- **Dokumen Referensi:**
  1. *Blueprint Aplikasi Mobile: SakuBuku 📓*
  2. *Analisis Kritis dan Identifikasi Celah Penelitian: Pengaruh Tingkat Kompresi JPEG terhadap Ukuran File Foto Struk Transaksi dan Akurasi Ekstraksi Data pada Aplikasi Keuangan Mobile*
- **Target Platform:** Mobile (Android & iOS) via Flutter Framework
- **Prinsip Operasional:** 100% Offline-First, Zero-Login, Maximum Privacy, Memory-Safe (<120MB Native Heap), Ultra-Efficient Storage (<120KB per Struk)

---

## 1. RINGKASAN EKSEKUTIF (EXECUTIVE SUMMARY)

Aplikasi **SakuBuku** dirancang sebagai solusi pencatatan keuangan pribadi dan operasional mikro (UMKM) yang berfokus pada kemudahan pencatatan harian, kecepatan interaksi, dan digitalisasi bukti fisik transaksi (nota/struk) tanpa membebani kapasitas penyimpanan internal ponsel pintar (*zero storage bloat*). Berbeda dari mayoritas aplikasi akuntansi modern yang menuntut konektivitas internet berkelanjutan (*cloud-dependent*) dan kewajiban registrasi akun pengguna (*login wall*), SakuBuku mengusung arsitektur **murni luring (*offline-first*)** demi menjamin kedaulatan privasi finansial pengguna secara mutlak.

Namun, pengintegrasian fitur digitalisasi struk fisik pada lingkungan seluler menghadirkan tantangan komputasi dan rekayasa perangkat lunak yang kompleks. Berdasarkan temuan mendalam pada dokumen *Analisis Gap Kompresi Struk Mobile*, implementasi kompresi citra standar (JPEG kuantisasi agresif) pada sistem operasi Android terbukti menyimpan **tiga jebakan arsitektural fatal**:
1. **Ilusi Ukuran File vs. Alokasi Memori Asli (*Out-of-Memory / OOM Threat*)**: Citra kamera modern (12 MP - 48 MP) memerlukan dekompresi menjadi objek `Bitmap ARGB_8888` berukuran 48 MB hingga 192 MB di *Native Heap* Android. Tanpa manipulasi *downsampling* dan alokasi *streaming*, pemrosesan foto nota akan langsung memicu *Garbage Collector thrashing* dan *crash fatal* pada perangkat kelas menengah ke bawah (*entry-level* RAM 2GB-3GB).
2. **Degradasi Keterbacaan dan Artefak Ringing (*Mosquito Noise*)**: Kompresi JPEG lossy dengan menurunkan *Quality Factor* (QF) secara ekstrem mengeliminasi koefisien frekuensi tinggi pada matriks *Discrete Cosine Transform* (DCT). Hal ini memicu artefak *blocking* (8x8) dan *ringing*, yang secara visual merusak batas karakter teks nota termal dan menyebabkan kegagalan katastropik jika diekstraksi oleh mesin *Optical Character Recognition* (OCR) di kemudian hari.
3. **Penyusutan Kerapatan Titik (*DPI Collapse*)**: Mengompresi dimensi gambar terlalu kecil (misal: lebar 800 piksel) tanpa pemotongan (*cropping*) area latar belakang meja akan menjatuhkan kerapatan piksel struk di bawah batas minimum keterbacaan (300 DPI), memicu hilangnya angka-angka kritis pada nominal uang (*Field-Level Accuracy drop*).

Dokumen ini menyajikan **Rencana Kerja Pengembangan (Development Work Plan)** yang komprehensif untuk memandu seluruh siklus hidup pengembangan SakuBuku. Dokumen ini mengawinkan rancang bangun fungsional 8 layar dari *Blueprint SakuBuku* dengan strategi mitigasi teknis mutakhir yang disintesis dari *Analisis Gap*, menghasilkan aplikasi keuangan yang tidak hanya kaya fitur dan estetik, tetapi juga stabil, tangguh, efisien, dan siap berevolusi menuju otomasi ekstraksi cerdas (*on-device OCR*).

---

## 2. ANALISIS KRITIS & SINTESIS KOMPARATIF (BLUEPRINT VS. ANALISIS GAP)

### 2.1 Evaluasi Desain Blueprint Asli SakuBuku
Blueprint SakuBuku menetapkan fondasi fungsional yang kuat:
- **8 Layar Utama**: Splash Screen, Home/Dashboard, Input Transaksi, Sub-Screen Kamera/Crop/Kompresi, Riwayat & Laporan, Analisis & Grafik, Pengaturan/Profil/Backup, serta Kalender Transaksi.
- **Teknologi**: Flutter, Isar Database/SQLite, Riverpod/Provider, `image_picker`, `image_cropper`, `flutter_image_compress`, `fl_chart`, `table_calendar`, dan `path_provider`.
- **Target Kompresi Awal**: Menggunakan `flutter_image_compress` dengan target format JPEG, quality 70%, lebar 800px, tinggi 1200px, untuk menyusutkan foto 3-5MB menjadi 50-150KB.

### 2.2 Identifikasi Celah dan Risiko Berdasarkan Analisis Gap
Dokumen *Analisis Gap Kompresi Struk Mobile* mengungkap celah kritis pada asumsi teknis tersebut:

| Komponen Blueprint Asli | Temuan Kritis Analisis Gap | Risiko & Dampak Teknis | Solusi Rekayasa yang Diadopsi SakuBuku |
| :--- | :--- | :--- | :--- |
| **Pipeline Kamera & Memori** (`image_picker` default) | Kamera 12-48MP mendekode bitmap penuh (48-192MB) di Native Heap saat proses crop & compress. | Crash *Out-of-Memory* (OOM) pada ponsel Android murah (RAM 2-3GB) saat pengguna mengambil foto resolusi penuh. | Konfigurasi `maxWidth: 1920, maxHeight: 1080` dan `imageQuality: 85` langsung pada saat capture kamera (`image_picker`), serta konversi decoding ke `RGB_565` (2 byte/px). |
| **Parameter Kompresi** (Lebar tetap 800px) | Lebar 800px pada struk fisik 80mm hanya menghasilkan ~250 DPI. Jika foto belum di-crop pas (ada meja/latar), resolusi teks jatuh ke <120 DPI. | Angka nominal kecil (font 7-8pt) pada struk termal menjadi buram, tidak terbaca oleh manusia saat di-zoom, dan gagal dipindai OCR. | **Kewajiban Cropping (Mandatory ROI)**: Pengguna memotong area struk terlebih dahulu. Parameter kompresi dinamis: lebar dipertahankan minimal 1080-1200px khusus untuk area struk terpilih guna mempertahankan resolusi >= 300 DPI. |
| **Format Kompresi** (Standar JPEG QF 70) | Standar JPEG menggunakan tabel kuantisasi psiko-visual alami yang memotong frekuensi tinggi teks, menciptakan *ringing / mosquito noise* di sekitar angka. | Angka nominal "10.000" dapat terbaca "1O.OOO" atau "18.000" akibat ringing yang menutup celah kurva karakter. | Penggunaan **WebP Lossy (QF 75)** sebagai format primer (25-30% lebih hemat dari JPEG dengan degradasi tepi yang jauh lebih halus), dengan fallback ke JPEG (QF 72, subsampling 4:2:0 via libjpeg-turbo). |
| **Karakteristik Kertas Struk** (Asumsi foto struk selalu bersih) | Struk menggunakan kertas termal yang mudah pudar, minim kontras, rentan noda/lipatan, dan sering difoto dalam kondisi pencahayaan bergradasi (bayangan HP/tangan). | Kontras teks dan kertas menyatu saat dikompresi; gambar tampak kusam dan teks tipis terhapus. | Prapemrosesan penajaman kontras ringan (*adaptive contrast enhancement* / CLAHE ringan) sebelum proses penyimpanan akhir. |
| **Penyimpanan Lokal** (`path_provider` sandboxed) | Blueprint belum memitigasi akumulasi file *temporary* hasil *image_picker* dan *image_cropper* di direktori `cache`. | Memori internal perangkat penuh oleh file *cache intermediate* yang tidak terhapus. | Mekanisme *Auto-Cleanup Garbage File*: Membersihkan berkas sementara di folder `tmp/cache` sesaat setelah berkas final tersimpan di sandboxed documents. |
| **Kesiapan Masa Depan (OCR)** (Blueprint manual input) | Blueprint hanya menargetkan penyimpanan foto nota sebagai arsip visual lampiran transaksi. | Pengguna tetap harus mengetik nominal secara manual; potensi otomasi finansial belum terwujud. | Penambahan **Fase Arsitektur Lanjutan**: Integrasi On-Device OCR (*Google ML Kit Text Recognition v2*) dengan *Smart Heuristic Parser* untuk ekstraksi otomatis nominal Rp, tanggal, dan nama toko. |

---

## 3. ARSITEKTUR SISTEM & SPESIFIKASI REKAYASA YANG DISEMPURNAKAN

### 3.1 Ringkasan Arsitektur Aplikasi
SakuBuku dibangun menggunakan arsitektur **Clean Architecture** berlapis (*Domain*, *Data*, dan *Presentation*) dengan pola *Feature-first* untuk memastikan skalabilitas, kemudahan pengujian (*testability*), dan keterpisahan tanggung jawab antar modul (*separation of concerns*).

```
                      ┌────────────────────────────────────────┐
                      │          PRESENTATION LAYER            │
                      │  (8 Screens, Widgets, Riverpod State)  │
                      └───────────────────┬────────────────────┘
                                          │
                                          ▼
                      ┌────────────────────────────────────────┐
                      │             DOMAIN LAYER               │
                      │   (Use Cases, Entities, Business Rules) │
                      └───────────────────┬────────────────────┘
                                          │
                                          ▼
                      ┌────────────────────────────────────────┐
                      │              DATA LAYER                │
                      │  Repositories, Isar DB, Image Pipeline │
                      └───────┬────────────────────────┬───────┘
                              │                        │
                              ▼                        ▼
                      ┌───────────────┐        ┌───────────────┐
                      │ Isar Database │        │ Storage (FS)  │
                      │  (Local ACID) │        │ (Sandboxed)   │
                      └───────────────┘        └───────────────┘
```

### 3.2 Spesifikasi Teknologi (Tech Stack)
1. **Core Framework:** Flutter SDK 3.24+ (Dart 3.5+)
2. **Local Database Engine:**
   - **Isar Database v3.1+**: Mesin basis data NoSQL statis (*zero-serialization*), eksekusi kueri lokal instan (<2ms), dukungan indeks multi-kolom, dan konsumsi memori minimal.
   - *Alternatif Fallback:* SQLite via `sqflite` dengan *repository pattern* terisolasi.
3. **State Management & Dependency Injection:** Riverpod 2.x dengan *code generation* (`flutter_riverpod`, `riverpod_annotation`).
4. **Subsistem Manajemen Citra & Kompresi:**
   - `image_picker` (dengan pembatasan resolusi kamera awal).
   - `image_cropper` (ROI isolation: memotong area non-struk).
   - `flutter_image_compress` (WebP / JPEG libjpeg-turbo encoder).
   - `path_provider` (manajemen lokasi berkas aman di direktori aplikasi).
5. **Visualisasi Data & Interaktivitas UI:**
   - `fl_chart` (Line chart tren saldo 7 hari & Donut/Pie chart distribusi pengeluaran).
   - `table_calendar` (Kalender visualisasi pemasukan/pengeluaran dengan status dot).
   - `intl` (Pemformatan mata uang Rupiah `id_ID` dan tanggal lokal).
6. **Ekspor, Impor, & Backup:**
   - `archive` (kompresi berkas zip untuk mencadangkan database + seluruh foto nota).
   - `csv` & `share_plus` (ekspor transaksi ke format lembar kerja Excel/CSV).
7. **Subsistem On-Device Intelligence (Fase Lanjutan):**
   - `google_mlkit_text_recognition` (On-Device OCR luring berkecepatan tinggi tanpa kuota internet).

---

### 3.3 Pipeline Pemrosesan Citra Tahan-Banting (Memory-Safe Pipeline)

Untuk menanggulangi temuan *Analisis Gap* terkait lonjakan memori Bitmap (*OOM*) dan degradasi artefak, pipeline penangkapan dan kompresi foto nota dirancang sebagai berikut:

```
[Kamera HP / Galeri]
       │
       ▼  (Langkah 1: Restrained Resolution Ingestion)
[Resolusi Tangkapan Dibatasi: Maks. 1920x1080, Quality 85%]
       │
       ▼  (Langkah 2: Region of Interest / ROI Selection)
[Image Cropper Interface: Eliminasi Latar Belakang Meja/NROI]
       │
       ▼  (Langkah 3: Contrast Normalization / Edge Preservation)
[Pre-compression Check: Evaluasi Rasio Aspek & Penajaman Garis]
       │
       ▼  (Langkah 4: Adaptive Dual-Format Compression)
[Target Format: WebP Lossy (QF: 75) / JPEG (QF: 72, 4:2:0)]
[Min Width: 1080px | Min Height: 1400px -> Mempertahankan >=280-300 DPI]
       │
       ▼  (Langkah 5: Sandboxed Persistence & Cache Cleanup)
[Simpan ke /app_flutter/receipts/{uuid}.webp (Ukuran File: 50-110 KB)]
       │
       ▼  (Langkah 6: Garbage Cleanup)
[Hapus Seluruh Berkas Sementara di folder /cache/ /tmp/]
```

**Panduan Parameter Teknis Kompresi:**
```dart
// Implementasi kompresi adaptif aman memori
Future<File?> compressReceiptImage(File rawFile) async {
  final String targetPath = await ReceiptStorageService.generateReceiptPath();
  
  // Format WebP dipilih karena preservasi tepi karakter lebih unggul 
  // dan bebas dari grid blocking 8x8 khas DCT JPEG.
  var result = await FlutterImageCompress.compressAndGetFile(
    rawFile.absolute.path,
    targetPath,
    format: CompressFormat.webp, // Format utama: WebP
    quality: 75,                 // Sweet spot kurva kompresi (Analisis Gap Bagian 4.3)
    minWidth: 1080,              // Mempertahankan resolusi teks >= 300 DPI pada struk 80mm
    minHeight: 1440,
    keepExif: false,             // Buang metadata EXIF untuk menghemat ~10KB dan menjaga privasi
  );

  // Jika WebP tidak didukung (perangkat lawas), fallback ke JPEG dengan QF 72
  if (result == null) {
    result = await FlutterImageCompress.compressAndGetFile(
      rawFile.absolute.path,
      targetPath.replaceAll('.webp', '.jpg'),
      format: CompressFormat.jpeg,
      quality: 72,
      minWidth: 1080,
      minHeight: 1440,
      keepExif: false,
    );
  }

  // Bersihkan berkas mentah temporary dari memori/cache kamera
  if (await rawFile.exists()) {
    await rawFile.delete();
  }
  
  return result != null ? File(result.path) : null;
}
```

---

### 3.4 Skema Basis Data Teroptimasi (Isar Collection)

```dart
@collection
class TransactionRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String type; // 'INCOME' atau 'EXPENSE'

  @Index()
  late double amount; // Nominal transaksi

  @Index()
  late String category; // Misal: Makanan, Belanja, Gaji

  @Index()
  late DateTime date; // Waktu transaksi

  String? note; // Catatan deskriptif transaksi

  String? receiptImagePath; // Path absolut lokal di sandbox aplikasi

  int? receiptSizeBytes; // Ukuran file nota dalam byte (untuk storage widget)

  bool isOcrProcessed = false; // Flag apakah nominal didapat dari OCR

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

@collection
class AppPreference {
  Id id = Isar.autoIncrement;
  String userName = "Pengguna";
  bool isDarkMode = false;
  String currencyCode = "IDR";
  int receiptCompressionQuality = 75; // Parameter kompresi yang dapat disesuaikan
}
```

---

## 4. RENCANA KERJA PENGEMBANGAN (DEVELOPMENT WORK PLAN)

Pengembangan SakuBuku direncanakan berlangsung selama **10 Sprint (20 Pekan)** menggunakan kerangka kerja **Agile Scrum**. Setiap sprint berdurasi 2 pekan dengan sasaran rilis fungsional yang terukur (*Potentially Shippable Product Increment*).

```
========================================================================================
ROADMAP PENGEMBANGAN SAKUBUKU (10 SPRINT / 20 PEKAN)
========================================================================================
[Fase 1: Sprint 1-2] Fondasi Arsitektur, Core Financial Engine, & Database
[Fase 2: Sprint 3-4] Pipeline Kamera, ROI Cropping, & Kompresi Aman-Memori
[Fase 3: Sprint 5-6] UI/UX 8 Layar Lengkap, Charting, & Visualisasi Kalender
[Fase 4: Sprint 7-8] Backup/Restore Data & Modul Ekstraksi Cerdas (On-Device OCR)
[Fase 5: Sprint 9]   Quality Assurance, Memory Stress-Testing, & Kalibrasi Perangkat
[Fase 6: Sprint 10]  Hardening, Final Release Packaging, & Distribusi
========================================================================================
```

---

### FASE 1: FONDASI ARSITEKTUR, CORE FINANCIAL ENGINE, & DATABASE (Sprint 1 - Sprint 2)
*Tujuan: Membangun fondasi arsitektur Clean Architecture, repositori basis data lokal Isar, dan state management Riverpod yang kokoh dan teruji.*

#### Sprint 1: Project Scaffolding & Database Layer Setup
- **Tugas 1.1:** Inisialisasi repositori Flutter dengan arsitektur berlapis (*Feature-first Clean Architecture*).
- **Tugas 1.2:** Konfigurasi *Theme & Design System* (Skema warna modern, font Google Fonts *Inter/Plus Jakarta Sans*, dark/light mode tokens).
- **Tugas 1.3:** Implementasi Isar Database schema (`TransactionRecord`, `AppPreference`).
- **Tugas 1.4:** Pembuatan abstraksi *Repository Pattern* untuk transaksi keuangan (CRUD).
- **Tugas 1.5:** Penulisan *Unit Test* untuk operasi CRUD Isar Database (Target: Code coverage > 90%).

#### Sprint 2: Core Financial Domain & State Management
- **Tugas 2.1:** Pembuatan *Domain Use Cases* (Pencatatan Pemasukan, Pencatatan Pengeluaran, Agregasi Saldo, Kalkulasi Arus Kas Bulanan).
- **Tugas 2.2:** Integrasi Riverpod 2.x dengan *Code Generation* (`transactionListProvider`, `balanceSummaryProvider`).
- **Tugas 2.3:** Pembuatan utilitas pemformatan mata uang Rupiah (`id_ID`) dan kalkulator kalkulasi nominal uang bebas *floating-point error*.
- **Tugas 2.4:** Unit testing pada Use Cases kalkulasi keuangan dan agregasi saldo.

---

### FASE 2: PIPELINE KAMERA, ROI CROPPING, & KOMPRESI AMAN-MEMORI (Sprint 3 - Sprint 4)
*Tujuan: Mengimplementasikan sistem digitalisasi nota fisik yang kebal terhadap lonjakan alokasi memori (Zero-OOM) dan menghasilkan berkas nota berukuran 50-110 KB dengan keterbacaan teks maksimal (>=300 DPI).*

#### Sprint 3: Safe Camera Capture & ROI Cropping Interface
- **Tugas 3.1:** Konfigurasi integrasi `image_picker` dengan pembatasan resolusi tangkapan awal (`maxWidth: 1920`, `maxHeight: 1080`, `imageQuality: 85`) untuk membatasi alokasi Bitmap mentah di Native Heap di bawah 25 MB.
- **Tugas 3.2:** Integrasi `image_cropper` dengan panduan visual (*bounding guide*) khusus struk kasir, memaksa pengguna membuang latar belakang meja (eliminasi Non-ROI) sebelum kompresi.
- **Tugas 3.3:** Pembuatan antarmuka pratinjau nota (*Receipt Preview Sub-Screen*) dengan fitur zoom interaktif (*InteractiveViewer*) dan tombol hapus/ambil ulang.
- **Tugas 3.4:** Mekanisme penanganan izin akses kamera dan galeri Android (*Runtime Permission Handling*) yang ramah pengguna.

#### Sprint 4: Adaptive Compression Engine & Sandbox Storage Management
- **Tugas 4.1:** Pembuatan *ReceiptCompressionEngine* menggunakan `flutter_image_compress` dengan format WebP (Quality 75) dan fallback JPEG (Quality 72).
- **Tugas 4.2:** Algoritma penyesuaian dimensi dinamis: memastikan lebar struk terpilih tidak kurang dari 1080 piksel guna menjaga kerapatan >= 300 DPI pada teks nota termal.
- **Tugas 4.3:** Implementasi *Sandbox Storage Service* menggunakan `path_provider` untuk menyimpan nota di `/data/user/0/com.sakubuku/app_flutter/receipts/`.
- **Tugas 4.4:** Modul *Garbage Cleaner*: Penghapusan otomatis file temporer di folder `/cache` dan `/tmp` setelah kompresi berhasil.
- **Tugas 4.5:** Modul *Storage Usage Calculator* untuk menghitung konsumsi ruang memori riil (Database + File Nota) secara presisi.

---

### FASE 3: UI/UX 8 LAYAR LENGKAP, CHARTING, & KALENDER (Sprint 5 - Sprint 6)
*Tujuan: Mewujudkan seluruh antarmuka pengguna sesuai Blueprint dengan standar estetika visual tinggi, transisi halus, dan kemudahan akses.*

#### Sprint 5: Layar Utama, Input Transaksi, & Riwayat
- **Tugas 5.1 (Screen 1):** *Splash Screen* modern dengan animasi pembuka, inisialisasi basis data di latar belakang, dan verifikasi direktori penyimpanan.
- **Tugas 5.2 (Screen 2):** *Home / Dashboard Screen*:
  - Kartu Saldo (*Total Balance, Total Income, Total Expense*).
  - Grafik mini 7 hari (*Sparkline Trend* menggunakan `fl_chart`).
  - Daftar transaksi hari ini (*Quick Daily List*) dengan ilustrasi jika kosong.
  - Floating Action Button (FAB) beranimasi untuk entri kilat.
- **Tugas 5.3 (Screen 3):** *Layar Input Transaksi*:
  - Toggle geser Pemasukan (Hijau) / Pengeluaran (Merah).
  - Custom Numeric Keypad dengan pemformatan otomatis Rupiah (`Rp xxx.xxx`).
  - Grid pemilihan ikon kategori (Makanan, Belanja, Transportasi, Gaji, dll.).
  - Tombol lampiran nota dengan thumbnail indikator klip kertas jika ada foto.
- **Tugas 5.4 (Screen 5):** *Riwayat & Laporan*:
  - List transaksi terkelompok per tanggal (*Sticky Header*).
  - Filter interaktif berdasarkan bulan, minggu, dan tipe transaksi.
  - Indikator visual lampiran nota (klik untuk membuka *Receipt Viewer modal*).

#### Sprint 6: Analisis Visual, Preferensi, & Kalender
- **Tugas 6.1 (Screen 6):** *Layar Analisis & Grafik*:
  - Interactive Donut Chart pengeluaran per kategori (`fl_chart`).
  - Bar Chart perbandingan bulanan pemasukan vs pengeluaran.
  - Ringkasan metrik finansial: Pengeluaran harian rata-rata dan kategori paling boros.
- **Tugas 6.2 (Screen 7):** *Profil & Pengaturan*:
  - Input nama sapaan pengguna untuk personalisasi dashboard.
  - Dark Mode / Light Mode manual toggle.
  - Widget Info Penyimpanan: Menampilkan kapasitas MB yang dihabiskan aplikasi (pembuktian efisiensi fitur kompresi).
- **Tugas 6.3 (Screen 8):** *Kalender Finansial*:
  - Integrasi `table_calendar` dengan indikator dot berwarna (hijau/merah) pada tanggal yang memiliki transaksi.
  - Panel daftar rincian transaksi harian saat tanggal tertentu ditekan.

---

### FASE 4: BACKUP/RESTORE DATA & MODUL EKSTRAKSI CERDAS (Sprint 7 - Sprint 8)
*Tujuan: Memastikan keamanan data luring melalui modul pencadangan mandiri dan mengintegrasikan prototipe otomasi OCR on-device.*

#### Sprint 7: Sistem Backup & Restore Mandiri
- **Tugas 7.1:** Fitur *Ekspor Data ke CSV*: Pengguna dapat mengekspor seluruh rekaman transaksi ke lembar kerja Excel/CSV.
- **Tugas 7.2:** Fitur *Pencadangan Penuh (Full Archive Backup)*: Mengemas seluruh basis data Isar dan folder foto nota menjadi berkas terenkripsi/terkompresi `.sakubuku` (ZIP).
- **Tugas 7.3:** Fitur *Pemulihan Data (Restore Engine)*: Validasi integritas berkas cadangan dan pemulihan data transaksi serta foto nota ke lokasi sandbox.
- **Tugas 7.4:** Fitur *Reset Data*: Opsi pembersihan basis data dan penghapusan seluruh berkas foto secara tuntas dengan konfirmasi ganda.

#### Sprint 8: Prototipe Ekstraksi Cerdas On-Device OCR (ML Kit & Heuristic Parser)
- **Tugas 8.1:** Integrasi `google_mlkit_text_recognition` luring (tidak memerlukan kuota internet).
- **Tugas 8.2:** *Smart Financial Heuristic Parser*:
  - Ekstraksi nominal total uang menggunakan pola Regex (deteksi kata kunci: *Total, Tagihan, Rp, Subtotal, Grand Total*).
  - Algoritma normalisasi distorsi karakter: Mengatasi artefak kompresi (misal: penggantian otomatis karakter 'O'/'o' menjadi '0' pada blok angka, 'l'/'I' menjadi '1').
  - Ekstraksi tanggal transaksi otomatis dari teks struk.
- **Tugas 8.3:** Antarmuka konfirmasi input: Nominal hasil OCR dimasukkan otomatis ke kolom input dengan status penanda "*Periksa kembali hasil bacaan nota*".

---

### FASE 5: QUALITY ASSURANCE, MEMORY STRESS-TESTING, & BENCHMARKING (Sprint 9)
*Tujuan: Memvalidasi kestabilan sistem di perangkat low-end dan memastikan seluruh target tolok ukur teknis terpenuhi.*

- **Tugas 9.1:** *Memory Stress Testing* pada ponsel Android RAM 2GB-3GB: Pengambilan dan kompresi 20 nota berturut-turut untuk memverifikasi tidak adanya *memory leak* atau *OOM Crash*.
- **Tugas 9.2:** *Compression Ratio & Legibility Benchmark*: Pengujian pada 50 sampel struk belanja riil (struk Indomaret, Alfamart, SPBU, EDC, restoran):
  - Memverifikasi ukuran file rata-rata tetap berada pada rentang 50 KB - 110 KB.
  - Memverifikasi teks nota tetap terbaca jelas (keterbacaan visual 100%).
- **Tugas 9.3:** *Field-Level Accuracy Benchmark* (OCR): Mengukur akurasi ekstraksi nominal uang pada struk terkompresi (Target: > 85% akurasi field).
- **Tugas 9.4:** *Battery & CPU Profiling*: Memastikan konsumsi baterai dan latensi kompresi di bawah 1.5 detik per nota.

---

### FASE 6: FINALISASI, HARDENING, & RILIS PRODUKSI (Sprint 10)
*Tujuan: Mempersiapkan aplikasi untuk rilis produksi yang aman, teroptimasi, dan terdokumentasi.*

- **Tugas 10.1:** Optimasi build release Flutter: Konfigurasi ProGuard, R8, dan *resource shrinking* pada Android untuk memangkas ukuran APK hingga < 20 MB.
- **Tugas 10.2:** Pengujian regresi menyeluruh (*Full End-to-End Testing*) pada semua alur fungsional 8 layar.
- **Tugas 10.3:** Pembuatan panduan pengguna (*In-app Onboarding / User Guide*) yang menjelaskan manfaat kompresi nota dan cara kerja backup offline.
- **Tugas 10.4:** Finalisasi distribusi berkas produksi (APK rilis & Android App Bundle / AAB).

---

## 5. WORK BREAKDOWN STRUCTURE (WBS) & MATRIKS RACI

### 5.1 Work Breakdown Structure (WBS)

```
1. INITIATION & ARCHITECTURE FOUNDATION
   1.1 Project Setup & CI Pipeline
   1.2 Design System & Typography Definition
   1.3 Isar Local Database Architecture
   1.4 Core Financial Domain Entities & Repositories
   1.5 Riverpod State Architecture

2. IMAGE SUBSYSTEM & COMPRESSION ENGINEERING
   2.1 Restrained Camera Capture Module
   2.2 ROI Cropping Integration (Table Elimination)
   2.3 Adaptive WebP/JPEG Compression Engine
   2.4 Native Heap Memory Safety & OOM Mitigation
   2.5 Storage Sandbox & Auto Garbage Cleaner

3. CORE FEATURE IMPLEMENTATION (8 SCREENS)
   3.1 Splash & Local Initialization Screen
   3.2 Dashboard & Financial Health Summary Screen
   3.3 Transaction Input & Keypad Screen
   3.4 Camera, Cropping, & Compression Sub-Screen
   3.5 Transaction History & Multi-Filter Screen
   3.6 Financial Analysis & Interactive Charts Screen
   3.7 Profile, Dark Mode, & Storage Info Screen
   3.8 Financial Calendar with Dot Markers Screen

4. DATA PERSISTENCE, BACKUP, & SMART PARSER
   4.1 CSV Transaction Export Service
   4.2 Full Archive (DB + Receipts) ZIP Backup & Restore
   4.3 On-Device ML Kit OCR Pipeline
   4.4 Regex-Based Financial Heuristic Parser

5. TESTING, VALIDATION, & PRODUCTION RELEASE
   5.1 Unit & Integration Testing
   5.2 Android Low-End Memory Stress Testing
   5.3 Compression Ratio & Legibility Benchmark
   5.4 Release Hardening (ProGuard, R8, APK Optimization)
   5.5 Production Release Packaging & Handover
```

---

### 5.2 Matriks Tanggung Jawab (RACI Matrix)

*Keterangan Peran:*
- **SA:** Solution Architect / Tech Lead
- **FLD:** Flutter Lead Developer
- **MIE:** Mobile Image & ML Engineer
- **UIX:** UI/UX Designer
- **QA:** Quality Assurance & Tester

| Kode WBS | Elemen Pekerjaan | SA | FLD | MIE | UIX | QA |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **1.1 - 1.2** | Project Architecture & Design System Setup | **A/R** | C | I | **R** | I |
| **1.3 - 1.5** | Isar Database & Core Financial Engine | A | **R** | I | I | C |
| **2.1 - 2.2** | Camera Capture & ROI Cropping Sub-system | A | C | **R** | C | C |
| **2.3 - 2.4** | Adaptive Compression & Native OOM Mitigation | **A** | C | **R** | I | C |
| **2.5** | Storage Sandbox & Garbage Cleaner | A | **R** | C | I | I |
| **3.1 - 3.4** | UI Screens: Splash, Home, Input, Camera Preview | I | **R** | C | **A** | C |
| **3.5 - 3.8** | UI Screens: History, Analytics, Settings, Calendar | I | **R** | I | **A** | C |
| **4.1 - 4.2** | Full Archive Backup & Restore Subsystem | A | **R** | I | I | C |
| **4.3 - 4.4** | On-Device ML Kit OCR & Smart Parser | A | C | **R** | C | C |
| **5.1 - 5.3** | Low-End Memory Stress Test & Compression QA | A | C | C | I | **R** |
| **5.4 - 5.5** | Production Release Build & Hardening | **A/R** | **R** | C | I | C |

*(R = Responsible, A = Accountable, C = Consulted, I = Informed)*

---

## 6. JADWAL PELAKSANAAN & TIMELINE (GANTT CHART)

| Sprint / Pekan | Aktivitas Utama | W1-2 | W3-4 | W5-6 | W7-8 | W9-10 | W11-12 | W13-14 | W15-16 | W17-18 | W19-20 |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Sprint 1 (Pekan 1-2)** | Setup Proyek, Design System, & Isar Schema | ██ | | | | | | | | | |
| **Sprint 2 (Pekan 3-4)** | Core Financial Engine & Riverpod Providers | | ██ | | | | | | | | |
| **Sprint 3 (Pekan 5-6)** | Safe Camera Pipeline & ROI Cropping Module | | | ██ | | | | | | | |
| **Sprint 4 (Pekan 7-8)** | Engine Kompresi WebP/JPEG & Anti-OOM Memory | | | | ██ | | | | | | |
| **Sprint 5 (Pekan 9-10)**| UI Screen 1-3, 5 (Home, Input, History) | | | | | ██ | | | | | |
| **Sprint 6 (Pekan 11-12)**| UI Screen 6-8 (Charts, Settings, Calendar) | | | | | | ██ | | | | |
| **Sprint 7 (Pekan 13-14)**| Backup/Restore Engine (ZIP/CSV) & Storage Info | | | | | | | ██ | | | |
| **Sprint 8 (Pekan 15-16)**| On-Device OCR & Heuristic Financial Parser | | | | | | | | ██ | | |
| **Sprint 9 (Pekan 17-18)**| Low-End Stress Testing & Benchmark Akurasi | | | | | | | | | ██ | |
| **Sprint 10 (Pekan 19-20)**| Hardening, Optimasi Release, & Final Handover | | | | | | | | | | ██ |

---

## 7. INDIKATOR KINERJA UTAMA (KPI) & TOLOK UKUR TEKNIS (BENCHMARKS)

Untuk menjamin kualitas hasil pengembangan, SakuBuku harus memenuhi parameter tolok ukur teknis (*Technical Benchmark Targets*) berikut:

| Parameter Evaluasi | Nilai Standar Industri / Tanpa Optimasi | Target Benchmark SakuBuku | Metode Pengukuran |
| :--- | :--- | :--- | :--- |
| **Ukuran Berkas per Struk** | 3.0 MB - 5.0 MB (Foto kamera langsung) | **50 KB - 110 KB** (Rasio kompresi > 96%) | Analisis statistik ukuran berkas di direktori sandbox pada 100 sampel struk fisik. |
| **Puncak Konsumsi RAM (*Peak RAM*)** | > 180 MB (Potensi OOM tinggi) | **< 85 MB** (Aman pada ponsel RAM 2GB) | Profiling alokasi *Native Heap* via Android Studio Profiler saat proses pengambilan foto & kompresi. |
| **Tingkat Keterbacaan Teks Struk** | Sering buram jika di-downsample naif | **100% Keterbacaan Visual** (DPI >= 300) | Pengujian visual manusia pada teks berukuran 7-8pt dengan pembesaran 200%. |
| **Kecepatan Kompresi & Simpan** | 2.5 - 4.0 detik | **< 1.2 detik** per nota | Pengukuran waktu eksekusi mulai dari tombol simpan ditekan hingga berkas tersimpan di sandbox. |
| **Waktu Boot Aplikasi (*Cold Start*)** | > 2.5 detik | **< 1.0 detik** | Pengukuran startup dari Splash Screen ke Dashboard menggunakan Android Vitals. |
| **Akurasi Field OCR (Nominal Rp)** | < 60% pada gambar terkompresi agresif | **> 85% Field-Level Accuracy** | Evaluasi perbandingan teks hasil ekstraksi ML Kit terhadap *ground truth* 100 struk belanja. |
| **Tingkat Stabilitas (*Crash-Free*)** | 97.0% | **>= 99.8% Crash-Free Sessions** | Stress-testing otomatis (1000 iterasi transaksi beruntun). |

---

## 8. MANAJEMEN RISIKO & STRATEGI MITIGASI (RISK REGISTER)

| No | Identifikasi Risiko | Tingkat Probabilitas | Tingkat Dampak | Strategi Mitigasi Proaktif & Rencana Kontingensi |
| :---: | :--- | :---: | :---: | :--- |
| **R1** | **Crash Out-of-Memory (OOM) pada ponsel Android murah (RAM 2GB)** saat memproses foto kamera resolusi tinggi. | Sedang | **Kritis** | Batasi resolusi tangkapan kamera sejak awal (`image_picker` max width 1920x1080), decode menggunakan `RGB_565`, dan panggil `Garbage Collector` secara eksplisit pasca-kompresi. |
| **R2** | **Teks struk termal pudar terhapus** akibat kuantisasi DCT JPEG yang membuang frekuensi tinggi. | Tinggi | **Tinggi** | Terapkan format **WebP Lossy** sebagai format primer, lakukan penajaman kontras lokal (*CLAHE* ringan), dan pertahankan lebar minimal 1080px pada area struk hasil crop. |
| **R3** | **Penumpukan file sampah sementara (*cache bloat*)** di memori internal pengguna akibat proses crop. | Tinggi | Sedang | Implementasikan modul *Auto-Garbage Collector* yang secara deterministik membersihkan file di folder `cache` dan `tmp` setiap kali proses simpan transaksi selesai atau dibatalkan. |
| **R4** | **Kerusakan berkas basis data lokal (*database corruption*)** saat perangkat mendadak mati/kehabisan baterai. | Rendah | **Kritis** | Isar Database memiliki sifat ACID murni dengan write-ahead logging; sediakan fitur pencadangan berkas otomatis lokal berkala ke folder dokumen publik. |
| **R5** | **Pengguna lupa memotong latar meja (NROI)**, menyebabkan alokasi piksel terbuang untuk latar kayu/lantai. | Sedang | Sedang | Hadirkan antarmuka pemotongan (*Cropper*) yang intuitif dengan *aspect ratio presets* dan pesan panduan visual singkat: *"Posisikan kotak pemotong pas pada kertas struk"*. |
| **R6** | **Kesalahan pembacaan angka nol/O oleh modul OCR** pada struk bernoda. | Tinggi | Sedang | Terapkan *Heuristic Character Normalization* (aturan koreksi otomatis) dan tampilkan dialog pratinjau konfirmasi agar pengguna selalu dapat memverifikasi nominal sebelum tersimpan. |

---

## 9. REKOMENDASI DAN LANGKAH EKSEKUSI SELANJUTNYA (NEXT STEPS)

Berdasarkan sintesis rancang bangun dan mitigasi risiko di atas, berikut adalah langkah konkret yang disarankan untuk segera dieksekusi:

1. **Sprint 1 Kickoff:** Inisialisasi arsitektur proyek Flutter dengan Clean Architecture terstruktur, setup pustaka Isar Database, dan tetapkan token desain UI.
2. **Prototipe Pipeline Citra:** Segera buat *proof-of-concept* (PoC) modul kompresi WebP vs JPEG pada direktori scratch/pengujian untuk memvalidasi metrik ukuran file (<110 KB) dan DPI keterbacaan pada perangkat fisik Android target (terutama ponsel kelas menengah-bawah).
3. **Penyempurnaan Desain Antarmuka:** Finalisasi mock-up visual untuk 8 layar SakuBuku dengan fokus pada *one-handed usability*, kemudahan input angka nominal, dan kejelasan indikator nota.
4. **Validasi Heuristik Finansial:** Kumpulkan dataset 50-100 foto struk belanja Indonesia (kertas termal beragam kondisi) sebagai dataset uji standar (*benchmarking dataset*) untuk pengujian kompresi dan OCR.

---
*Dokumen ini merupakan pedoman resmi rekayasa perangkat lunak dan rencana kerja pelaksanaan pengembangan aplikasi SakuBuku.*
