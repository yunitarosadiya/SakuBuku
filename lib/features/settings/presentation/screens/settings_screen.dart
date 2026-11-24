import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sakubuku/core/constants/app_colors.dart';
import 'package:sakubuku/core/services/storage_service.dart';
import 'package:sakubuku/features/transactions/data/models/transaction_model.dart';
import 'package:sakubuku/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:share_plus/share_plus.dart';

enum _ExportRangeType {
  all,
  day,
  weekly,
  month,
  years,
  customRange,
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _formatShortDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String _formatFileTagDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '${d.year}$month$day';
  }

  Future<void> _showExportRangeSheet(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    DateTime selectedDate = now;
    int selectedYear = now.year;
    int selectedMonth = now.month;
    int customYearsCount = 3;
    DateTimeRange customDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            const monthNames = [
              'Januari',
              'Februari',
              'Maret',
              'April',
              'Mei',
              'Juni',
              'Juli',
              'Agustus',
              'September',
              'Oktober',
              'November',
              'Desember',
            ];

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.textMutedLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Text(
                        'Pilih Rentang Ekspor CSV',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sesuaikan periode riwayat transaksi yang ingin diunduh.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 16),

                      // 1. Keseluruhan
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.all_inclusive, color: AppColors.primary),
                        title: const Text('Keseluruhan Data', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Semua transaksi dari awal hingga sekarang'),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _runExportCsv(
                            context,
                            ref,
                            rangeType: _ExportRangeType.all,
                            labelSuffix: 'keseluruhan',
                          );
                        },
                      ),

                      // 2. Per Hari (Pilih Tanggal)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.today, color: AppColors.primary),
                        title: const Text('Per Hari', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Tanggal terpilih: ${_formatShortDate(selectedDate)}'),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2015),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Ubah Tgl'),
                        ),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _runExportCsv(
                            context,
                            ref,
                            rangeType: _ExportRangeType.day,
                            anchorDate: selectedDate,
                            labelSuffix: 'hari_${_formatFileTagDate(selectedDate)}',
                          );
                        },
                      ),

                      // 3. Mingguan (7 Hari Terakhir dari Tanggal Acuan)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range, color: AppColors.primary),
                        title: const Text('Mingguan (7 Hari)', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Rentang 7 hari sampai ${_formatShortDate(selectedDate)}'),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _runExportCsv(
                            context,
                            ref,
                            rangeType: _ExportRangeType.weekly,
                            anchorDate: selectedDate,
                            labelSuffix: 'mingguan_7hari',
                          );
                        },
                      ),

                      // 4. Per Bulan (Pilih Bulan & Tahun)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                        title: const Text('Per Bulan', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Bulan terpilih: ${monthNames[selectedMonth - 1]} $selectedYear'),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await _pickYearMonthDialog(
                              ctx,
                              initialYear: selectedYear,
                              initialMonth: selectedMonth,
                              monthNames: monthNames,
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedYear = picked.year;
                                selectedMonth = picked.month;
                              });
                            }
                          },
                          child: const Text('Pilih Bulan'),
                        ),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _runExportCsv(
                            context,
                            ref,
                            rangeType: _ExportRangeType.month,
                            year: selectedYear,
                            month: selectedMonth,
                            labelSuffix:
                                'bulan_${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}',
                          );
                        },
                      ),

                      const Divider(height: 20),

                      // 5. Rentang Tahun Bebas (1, 2, 3, 4, 5+ Tahun)
                      const Text(
                        'Rentang Tahun Terakhir',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [1, 2, 3, 4, 5].map((yr) {
                                  final active = customYearsCount == yr;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('$yr Thn'),
                                      selected: active,
                                      onSelected: (_) {
                                        setModalState(() => customYearsCount = yr);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: customYearsCount > 1
                                ? () => setModalState(() => customYearsCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$customYearsCount thn',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: customYearsCount < 15
                                ? () => setModalState(() => customYearsCount++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _runExportCsv(
                              context,
                              ref,
                              rangeType: _ExportRangeType.years,
                              anchorDate: DateTime.now(),
                              yearsCount: customYearsCount,
                              labelSuffix: '${customYearsCount}_tahun',
                            );
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: Text('Ekspor $customYearsCount Tahun Terakhir'),
                        ),
                      ),

                      const Divider(height: 20),

                      // 6. Rentang Tanggal Bebas (Dari - Sampai)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_calendar, color: AppColors.primary),
                        title: const Text('Rentang Tanggal Bebas', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${_formatShortDate(customDateRange.start)}  –  ${_formatShortDate(customDateRange.end)}',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: ctx,
                              firstDate: DateTime(2015),
                              lastDate: DateTime(2035),
                              initialDateRange: customDateRange,
                            );
                            if (picked != null) {
                              setModalState(() => customDateRange = picked);
                            }
                          },
                          child: const Text('Atur Tgl'),
                        ),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _runExportCsv(
                            context,
                            ref,
                            rangeType: _ExportRangeType.customRange,
                            dateRange: customDateRange,
                            labelSuffix:
                                'rentang_${_formatFileTagDate(customDateRange.start)}_${_formatFileTagDate(customDateRange.end)}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickYearMonthDialog(
    BuildContext context, {
    required int initialYear,
    required int initialMonth,
    required List<String> monthNames,
  }) async {
    int year = initialYear;
    int month = initialMonth;

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pilih Bulan & Tahun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => year--),
                  ),
                  Text('$year', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => year++),
                  ),
                ],
              ),
              const Divider(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (idx) {
                  final m = idx + 1;
                  return ChoiceChip(
                    label: Text(monthNames[idx].substring(0, 3)),
                    selected: month == m,
                    onSelected: (_) => setState(() => month = m),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, DateTime(year, month, 1)),
              child: const Text('Pilih'),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _filterTransactionsByRange(
    List<TransactionModel> source, {
    required _ExportRangeType rangeType,
    DateTime? anchorDate,
    int? year,
    int? month,
    int? yearsCount,
    DateTimeRange? dateRange,
  }) {
    final now = anchorDate ?? DateTime.now();

    switch (rangeType) {
      case _ExportRangeType.all:
        return source;

      case _ExportRangeType.day:
        return source.where((t) {
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        }).toList();

      case _ExportRangeType.weekly:
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        final startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return source.where((t) {
          return !t.date.isBefore(startDate) && !t.date.isAfter(endOfDay);
        }).toList();

      case _ExportRangeType.month:
        final targetYear = year ?? now.year;
        final targetMonth = month ?? now.month;
        return source.where((t) {
          return t.date.year == targetYear && t.date.month == targetMonth;
        }).toList();

      case _ExportRangeType.years:
        final count = (yearsCount ?? 1).clamp(1, 50);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        final startDate = DateTime(now.year - count, now.month, now.day);
        return source.where((t) {
          return !t.date.isBefore(startDate) && !t.date.isAfter(endOfDay);
        }).toList();

      case _ExportRangeType.customRange:
        if (dateRange == null) return source;
        final startOfDay = DateTime(
          dateRange.start.year,
          dateRange.start.month,
          dateRange.start.day,
        );
        final endOfDay = DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day,
          23,
          59,
          59,
          999,
        );
        return source.where((t) {
          return !t.date.isBefore(startOfDay) && !t.date.isAfter(endOfDay);
        }).toList();
    }
  }

  Future<void> _runExportCsv(
    BuildContext context,
    WidgetRef ref, {
    required _ExportRangeType rangeType,
    required String labelSuffix,
    DateTime? anchorDate,
    int? year,
    int? month,
    int? yearsCount,
    DateTimeRange? dateRange,
  }) async {
    try {
      final List<TransactionModel> allTransactions =
          await ref.read(transactionRepositoryProvider).getAllTransactions();

      final List<TransactionModel> filtered = _filterTransactionsByRange(
        allTransactions,
        rangeType: rangeType,
        anchorDate: anchorDate,
        year: year,
        month: month,
        yearsCount: yearsCount,
        dateRange: dateRange,
      );

      if (filtered.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada transaksi pada rentang waktu yang dipilih.'),
            ),
          );
        }
        return;
      }

      final List<List<dynamic>> rows = [
        [
          'ID',
          'Tipe',
          'Nominal',
          'Kategori',
          'Tanggal',
          'Catatan',
          'Punya Nota',
          'Ukuran Nota (Bytes)',
        ],
        ...filtered.map((t) => [
              t.id ?? '',
              t.type,
              t.amount.toStringAsFixed(0),
              t.category,
              t.date.toIso8601String(),
              t.note,
              t.hasReceipt ? 'Ya' : 'Tidak',
              t.receiptSizeBytes ?? 0,
            ]),
      ];

      final String csvString = const ListToCsvConverter().convert(rows);
      final String fileName =
          'sakubuku_${labelSuffix}_${DateTime.now().millisecondsSinceEpoch}.csv';

      if (kIsWeb) {
        final bytes = Uint8List.fromList(utf8.encode(csvString));
        await Share.shareXFiles(
          [XFile.fromData(bytes, name: fileName, mimeType: 'text/csv')],
          text: 'Ekspor Data Transaksi SakuBuku ($labelSuffix)',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File $fileName (${filtered.length} data) siap diunduh.')),
          );
        }
        return;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/$fileName');
      await file.writeAsString(csvString, flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV dibuat (${filtered.length} data): $fileName')),
        );
      }

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Ekspor Data Transaksi SakuBuku ($labelSuffix)',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profil Sapaan Sederhana
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengguna SakuBuku',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mode Privat (100% Offline-First)',
                          style: TextStyle(fontSize: 12, color: AppColors.incomeDark, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Widget Pemantau Penyimpanan (Bukti Fitur Kompresi)
            const Text(
              'Statistik Penyimpanan Memori',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            storageAsync.when(
              data: (info) => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Memori Digunakan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          info.totalSizeFormatted,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildStorageRow('Basis Data SQLite', info.databaseSizeFormatted, Icons.storage),
                    const SizedBox(height: 8),
                    _buildStorageRow('Foto Nota Terkompresi', '${info.receiptsSizeFormatted} (${info.receiptsCount} foto)', Icons.image),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final cleaned = await StorageService.cleanTemporaryFiles();
                        ref.invalidate(storageInfoProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Berhasil membersihkan $cleaned file sampah temporary')),
                          );
                        }
                      },
                      icon: const Icon(Icons.cleaning_services, size: 16),
                      label: const Text('Bersihkan Cache Temporer'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Gagal membaca storage: $err'),
            ),
            const SizedBox(height: 24),

            // 3. Manajemen Data & Privasi
            const Text(
              'Manajemen Data',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                    title: const Text('Ekspor Data ke CSV', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Pilih rentang waktu & buka di Excel / Sheets', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showExportRangeSheet(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.expense),
                    title: const Text('Hapus Seluruh Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.expense)),
                    subtitle: const Text('Reset basis data dan hapus semua foto nota', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Seluruh Data?'),
                          content: const Text('Tindakan ini akan mengosongkan database dan menghapus semua foto nota secara permanen.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Hapus Semua'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(transactionRepositoryProvider).clearAllData();
                        ref.invalidate(transactionListProvider);
                        ref.invalidate(balanceSummaryProvider);
                        ref.invalidate(monthlySummaryProvider);
                        ref.invalidate(todayTransactionsProvider);
                        ref.invalidate(storageInfoProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Semua data berhasil dibersihkan')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. Tentang Aplikasi
            Center(
              child: Column(
                children: [
                  const Text('SakuBuku v1.0.0', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Aplikasi Keuangan Pribadi Murni Luring (Offline-First)', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 2),
                  Text('Dilengkapi Kompresi Struk Aman Memori (Anti-OOM)', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}