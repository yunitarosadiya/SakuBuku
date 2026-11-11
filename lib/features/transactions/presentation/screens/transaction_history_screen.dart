import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/default_categories.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final monthlySummaryAsync = ref.watch(monthlySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          // Selector Bulan & Tahun
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
              label: Text(
                DateFormatter.formatMonthYear(DateTime(filter.year, filter.month)),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () => _pickMonth(context, ref, filter),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ringkasan Bulan Terpilih (Mini Card)
          _buildMonthSummaryCard(context, monthlySummaryAsync),

          // Filter Tab Bar (Semua / Pengeluaran / Pemasukan)
          _buildTypeFilterChips(ref, filter),
          const SizedBox(height: 8),

          // Daftar Transaksi
          Expanded(
            child: transactionsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(context);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(transactionListProvider.notifier).refresh();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildHistoryItem(context, item);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryCard(BuildContext context, AsyncValue<Map<String, double>> summaryAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: summaryAsync.when(
        data: (summary) {
          final income = summary['monthlyIncome'] ?? 0.0;
          final expense = summary['monthlyExpense'] ?? 0.0;
          final net = summary['monthlyNet'] ?? 0.0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryColumn('Pemasukan', income, AppColors.income),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              _buildSummaryColumn('Pengeluaran', expense, AppColors.expense),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              _buildSummaryColumn('Selisih Kas', net, net >= 0 ? AppColors.income : AppColors.expense),
            ],
          );
        },
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatRupiah(amount),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildTypeFilterChips(WidgetRef ref, TransactionFilterState filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: filter.typeFilter == null,
            onSelected: (_) {
              ref.read(transactionFilterProvider.notifier).updateFilter(
                    filter.copyWith(clearType: true),
                  );
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Pengeluaran'),
            selected: filter.typeFilter == 'EXPENSE',
            selectedColor: AppColors.expenseLight,
            onSelected: (_) {
              ref.read(transactionFilterProvider.notifier).updateFilter(
                    filter.copyWith(typeFilter: 'EXPENSE'),
                  );
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Pemasukan'),
            selected: filter.typeFilter == 'INCOME',
            selectedColor: AppColors.incomeLight,
            onSelected: (_) {
              ref.read(transactionFilterProvider.notifier).updateFilter(
                    filter.copyWith(typeFilter: 'INCOME'),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, TransactionModel item) {
    final category = DefaultCategories.getCategoryByName(item.category, item.type);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionScreen(editItem: item),
          ),
        );
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.category,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (item.hasReceipt) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.formatShort(item.date)} • ${item.note.isNotEmpty ? item.note : "Tanpa catatan"}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatWithSign(item.amount, item.type),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: item.isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMutedLight),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Transaksi pada Periode Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Ubah filter bulan atau catat transaksi baru untuk melihat riwayat keuangan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context, WidgetRef ref, TransactionFilterState current) async {
    int selectedYear = current.year;
    int selectedMonth = current.month;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pilih Bulan & Tahun'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => selectedYear--),
                      ),
                      Text(
                        '$selectedYear',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() => selectedYear++),
                      ),
                    ],
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final monthIndex = index + 1;
                      final isSelected = selectedMonth == monthIndex;
                      return ChoiceChip(
                        label: Text(DateFormatter.formatMonthYear(DateTime(2026, monthIndex)).split(' ')[0]),
                        selected: isSelected,
                        onSelected: (_) => setState(() => selectedMonth = monthIndex),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'year': selectedYear, 'month': selectedMonth}),
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      ref.read(transactionFilterProvider.notifier).updateFilter(
            current.copyWith(year: result['year'], month: result['month']),
          );
    }
  }
}
