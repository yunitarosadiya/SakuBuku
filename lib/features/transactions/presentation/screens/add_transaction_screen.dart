import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:sakubuku/core/constants/app_colors.dart';
import 'package:sakubuku/core/constants/default_categories.dart';
import 'package:sakubuku/core/services/image_compression_service.dart';
import 'package:sakubuku/core/utils/currency_formatter.dart';
import 'package:sakubuku/core/utils/date_formatter.dart';
import 'package:sakubuku/features/transactions/data/models/transaction_model.dart';
import 'package:sakubuku/features/transactions/presentation/providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? editItem;

  const AddTransactionScreen({super.key, this.editItem});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late String _type; // 'EXPENSE' or 'INCOME'
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategory;

  File? _receiptFile;
  int? _receiptSizeBytes;
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _type = item?.type ?? 'EXPENSE';
    _amountController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: item?.note ?? '');
    _selectedDate = item?.date ?? DateTime.now();
    _selectedCategory = item?.category ??
        (_type == 'EXPENSE'
            ? DefaultCategories.expenseCategories.first.name
            : DefaultCategories.incomeCategories.first.name);

    if (item?.receiptImagePath != null) {
      _receiptFile = File(item!.receiptImagePath!);
      _receiptSizeBytes = item.receiptSizeBytes;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _selectedCategory = _type == 'EXPENSE'
          ? DefaultCategories.expenseCategories.first.name
          : DefaultCategories.incomeCategories.first.name;
    });
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picker = ImagePicker();
      // PENTING: Batasi resolusi capture awal ke 1920x1080 (Anti-OOM Ingestion)
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) return;

      // Alur Cropper: Mewajibkan pemotongan area struk untuk eliminasi Non-ROI
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Area Struk',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Potong Area Struk',
          ),
        ],
      );

      final File sourceForCompression = cropped != null ? File(cropped.path) : File(picked.path);

      setState(() => _isCompressing = true);

      // Jalankan Engine Kompresi Adaptif (WebP/JPEG sweet spot)
      final result = await ImageCompressionService.compressReceipt(sourceForCompression);

      setState(() {
        _isCompressing = false;
        if (result != null) {
          _receiptFile = result.file;
          _receiptSizeBytes = result.sizeBytes;
        }
      });
    } catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses gambar: $e')),
        );
      }
    }
  }

  Future<void> _saveTransaction() async {
    final amount = CurrencyFormatter.parseRaw(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transaksi harus lebih dari 0')),
      );
      return;
    }

    final item = TransactionModel(
      id: widget.editItem?.id,
      type: _type,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text.trim(),
      receiptImagePath: _receiptFile?.path,
      receiptSizeBytes: _receiptSizeBytes,
    );

    final notifier = ref.read(transactionListProvider.notifier);
    bool success;
    if (widget.editItem == null) {
      success = await notifier.addTransaction(item);
    } else {
      success = await notifier.updateTransaction(item);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi')),
        );
      }
    }
  }

  Future<void> _editUkuranNota() async {
    if (_receiptFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _receiptFile!.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Ukuran Nota',
          toolbarColor: AppColors.primary, // Memakai warna Pink dari temamu
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _receiptFile = File(croppedFile.path);
        // Memperbarui ukuran file setelah dipotong
        _receiptSizeBytes = _receiptFile!.lengthSync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'EXPENSE'
        ? DefaultCategories.expenseCategories
        : DefaultCategories.incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editItem == null ? 'Catat Transaksi' : 'Edit Transaksi'),
        actions: [
          if (widget.editItem != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Transaksi?'),
                    content: const Text('Data transaksi dan foto nota terlampir akan dihapus permanen.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await ref.read(transactionListProvider.notifier).deleteTransaction(widget.editItem!.id!);
                  nav.pop();
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Toggle Tab Tipe (Pengeluaran / Pemasukan)
            _buildTypeToggle(),
            const SizedBox(height: 24),

            // 2. Input Nominal Uang
            const Text(
              'Nominal',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            _buildAmountInput(),
            const SizedBox(height: 24),

            // 3. Pemilihan Kategori
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 10),
            _buildCategorySelector(categories),
            const SizedBox(height: 24),

            // 4. Tanggal & Waktu
            const Text(
              'Tanggal Transaksi',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            _buildDatePicker(),
            const SizedBox(height: 24),

            // 5. Catatan Bebas
            const Text(
              'Catatan (Opsional)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Misal: Makan siang di warung kopi',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // 6. Fitur Digitalisasi Nota (USP SakuBuku)
            _buildReceiptSection(),
            const SizedBox(height: 32),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isCompressing ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'EXPENSE' ? AppColors.expense : AppColors.income,
                ),
                child: _isCompressing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Mengompresi Foto Nota...'),
                        ],
                      )
                    : const Text(
                        'Simpan Transaksi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.borderLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onTypeChanged('EXPENSE'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == 'EXPENSE' ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pengeluaran',
                  style: TextStyle(
                    color: _type == 'EXPENSE' ? Colors.white : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onTypeChanged('INCOME'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == 'INCOME' ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pemasukan',
                  style: TextStyle(
                    color: _type == 'INCOME' ? Colors.white : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: _type == 'EXPENSE' ? AppColors.expense : AppColors.income,
      ),
      decoration: InputDecoration(
        prefixText: 'Rp ',
        prefixStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: _type == 'EXPENSE' ? AppColors.expense : AppColors.income,
        ),
        hintText: '0',
      ),
    );
  }

  Widget _buildCategorySelector(List<CategoryItem> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat.name;
        return FilterChip(
          selected: isSelected,
          avatar: Icon(
            cat.icon,
            size: 16,
            color: isSelected ? Colors.white : cat.color,
          ),
          label: Text(cat.name),
          selectedColor: cat.color,
          backgroundColor: Theme.of(context).cardTheme.color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
          checkmarkColor: Colors.white,
          onSelected: (_) {
            setState(() => _selectedCategory = cat.name);
          },
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormatter.formatFull(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bukti Struk / Nota',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            if (_receiptSizeBytes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Terkonpresi: ${(_receiptSizeBytes! / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.incomeDark),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_receiptFile != null && (kIsWeb || _receiptFile!.existsSync())) ...[
          // Pratinjau Nota
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (kIsWeb) return; // Mencegah error pop-up jika dijalankan di Web
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                panEnabled: true,
                                minScale: 1.0,
                                maxScale: 4.0, // Bisa di-zoom hingga 4x
                                child: Image.file(
                                  _receiptFile!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 40,
                                right: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Container(
                            width: 60,
                            height: 60,
                            color: AppColors.primaryLight.withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt, size: 30, color: AppColors.primary),
                          )
                        : Image.file(
                            _receiptFile!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nota Terlampir (WebP)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Memori hemat, teks struk tajam >=300 DPI',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                // 2. Menambahkan tombol Crop di sebelah tombol Silang
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.crop, color: AppColors.primary),
                      onPressed: _editUkuranNota, // Memanggil fungsi potong gambar
                      tooltip: 'Edit Ukuran',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.expense),
                      onPressed: () {
                        setState(() {
                          _receiptFile = null;
                          _receiptSizeBytes = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // Tombol Ambil Nota
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReceipt(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Foto Kamera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReceipt(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Dari Galeri'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
