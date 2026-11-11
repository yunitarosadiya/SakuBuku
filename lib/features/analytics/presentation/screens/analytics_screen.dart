import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakubuku/core/constants/app_colors.dart';
import 'package:sakubuku/core/constants/default_categories.dart';
import 'package:sakubuku/core/utils/currency_formatter.dart';
import 'package:sakubuku/core/utils/date_formatter.dart';
import 'package:sakubuku/features/transactions/presentation/providers/transaction_provider.dart';

final categoryBreakdownProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, type) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);
  return await repo.getCategoryBreakdown(filter.year, filter.month, type: type);
});

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedType = 'EXPENSE';
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final breakdownAsync = ref.watch(categoryBreakdownProvider(_selectedType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Keuangan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                DateFormatter.formatMonthYear(DateTime(filter.year, filter.month)),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Pengeluaran vs Pemasukan
            _buildTypeToggle(),
            const SizedBox(height: 24),

            // Card Donut Chart
            breakdownAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return _buildEmptyChart(context);
                }
                final double total = data.fold(0.0, (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0.0));
                return Column(
                  children: [
                    // Donut Chart Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _selectedType == 'EXPENSE' ? 'Distribusi Pengeluaran' : 'Distribusi Pemasukan',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ${CurrencyFormatter.formatRupiah(total)}',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                sections: _generateSections(data, total),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rincian Kategori List
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rincian per Kategori',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final catName = item['category'] as String;
                        final amount = (item['total'] as num).toDouble();
                        final count = item['count'] as int;
                        final percentage = total > 0 ? (amount / total * 100) : 0.0;
                        final category = DefaultCategories.getCategoryByName(catName, _selectedType);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(category.icon, color: category.color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Text(
                                      '$count Transaksi • ${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatRupiah(amount),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (err, _) => Text('Gagal memuat grafik: $err'),
            ),
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
              onTap: () => setState(() => _selectedType = 'EXPENSE'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedType == 'EXPENSE' ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pengeluaran',
                  style: TextStyle(
                    color: _selectedType == 'EXPENSE' ? Colors.white : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'INCOME'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedType == 'INCOME' ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pemasukan',
                  style: TextStyle(
                    color: _selectedType == 'INCOME' ? Colors.white : AppColors.textSecondaryLight,
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

  List<PieChartSectionData> _generateSections(List<Map<String, dynamic>> data, double total) {
    return List.generate(data.length, (i) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 65.0 : 50.0;
      final item = data[i];
      final amount = (item['total'] as num).toDouble();
      final percentage = total > 0 ? (amount / total * 100) : 0.0;
      final category = DefaultCategories.getCategoryByName(item['category'] as String, _selectedType);

      return PieChartSectionData(
        color: category.color,
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: AppColors.textMutedLight),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Data Grafik',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Catat transaksi pada bulan ini untuk melihat visualisasi pengeluaran dan pemasukan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}
