import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakubuku/core/constants/app_colors.dart';
import 'package:sakubuku/core/services/storage_service.dart';
import 'package:sakubuku/features/transactions/presentation/providers/transaction_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
                    subtitle: const Text('Buka riwayat transaksi di Microsoft Excel / Sheets', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur Ekspor CSV siap dikonfigurasi')),
                      );
                    },
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
