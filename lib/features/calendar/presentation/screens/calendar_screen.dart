import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sakubuku/core/constants/app_colors.dart';
import 'package:sakubuku/core/constants/default_categories.dart';
import 'package:sakubuku/core/utils/currency_formatter.dart';
import 'package:sakubuku/core/utils/date_formatter.dart';
import 'package:sakubuku/features/transactions/data/models/transaction_model.dart';
import 'package:sakubuku/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:sakubuku/features/transactions/presentation/screens/add_transaction_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Finansial'),
      ),
      body: transactionsAsync.when(
        data: (allMonthTransactions) {
          // Buat map tanggal -> list transaksi
          final Map<DateTime, List<TransactionModel>> eventsMap = {};
          for (final t in allMonthTransactions) {
            final dayKey = DateTime(t.date.year, t.date.month, t.date.day);
            eventsMap.putIfAbsent(dayKey, () => []).add(t);
          }

          final selectedDayKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
          final selectedTransactions = eventsMap[selectedDayKey] ?? [];

          return Column(
            children: [
              // Kalender Interaktif
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TableCalendar<TransactionModel>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return eventsMap[key] ?? [];
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      final hasIncome = events.any((e) => e.isIncome);
                      final hasExpense = events.any((e) => e.isExpense);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasIncome)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.income,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasExpense)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.expense,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    ref.read(transactionFilterProvider.notifier).updateFilter(
                          TransactionFilterState(year: focusedDay.year, month: focusedDay.month),
                        );
                  },
                ),
              ),

              // Header Tanggal Terpilih & Jumlah Transaksi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatFull(_selectedDay),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      '${selectedTransactions.length} Transaksi',
                      style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // List Transaksi Pada Tanggal Terpilih
              Expanded(
                child: selectedTransactions.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada transaksi pada tanggal ini',
                          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: selectedTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = selectedTransactions[index];
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
                                          item.category,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                        Text(
                                          item.note.isNotEmpty ? item.note : DateFormatter.formatTime(item.date),
                                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatWithSign(item.amount, item.type),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: item.isIncome ? AppColors.income : AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat: $err')),
      ),
    );
  }
}
