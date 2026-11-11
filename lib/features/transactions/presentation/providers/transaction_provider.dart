import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

/// Provider instance TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// State filter transaksi (Bulan, Tahun, Tipe)
class TransactionFilterState {
  final int year;
  final int month;
  final String? typeFilter; // null for All, 'INCOME', 'EXPENSE'

  const TransactionFilterState({
    required this.year,
    required this.month,
    this.typeFilter,
  });

  TransactionFilterState copyWith({
    int? year,
    int? month,
    String? typeFilter,
    bool clearType = false,
  }) {
    return TransactionFilterState(
      year: year ?? this.year,
      month: month ?? this.month,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
    );
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() {
    final now = DateTime.now();
    return TransactionFilterState(year: now.year, month: now.month);
  }

  void updateFilter(TransactionFilterState filter) {
    state = filter;
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(() {
  return TransactionFilterNotifier();
});

/// Notifier untuk mengelola list transaksi secara reaktif
class TransactionListNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final filter = ref.watch(transactionFilterProvider);
    final repo = ref.watch(transactionRepositoryProvider);
    
    final items = await repo.getTransactionsByMonth(filter.year, filter.month);
    if (filter.typeFilter != null) {
      return items.where((t) => t.type.toUpperCase() == filter.typeFilter!.toUpperCase()).toList();
    }
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<bool> addTransaction(TransactionModel item) async {
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.addTransaction(item);
      ref.invalidateSelf();
      ref.invalidate(balanceSummaryProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(todayTransactionsProvider);
      ref.invalidate(storageInfoProvider);
      ref.invalidate(expenseTrendProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel item) async {
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.updateTransaction(item);
      ref.invalidateSelf();
      ref.invalidate(balanceSummaryProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(todayTransactionsProvider);
      ref.invalidate(storageInfoProvider);
      ref.invalidate(expenseTrendProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.deleteTransaction(id);
      ref.invalidateSelf();
      ref.invalidate(balanceSummaryProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(todayTransactionsProvider);
      ref.invalidate(storageInfoProvider);
      ref.invalidate(expenseTrendProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final transactionListProvider = AsyncNotifierProvider<TransactionListNotifier, List<TransactionModel>>(() {
  return TransactionListNotifier();
});

/// Provider total saldo sepanjang waktu
final balanceSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getBalanceSummary();
});

/// Provider ringkasan bulan berjalan
final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);
  return await repo.getMonthlySummary(filter.year, filter.month);
});

/// Provider transaksi hari ini (Dashboard)
final todayTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getTodayTransactions();
});

/// Provider tren pengeluaran 7 hari
final expenseTrendProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getDailyExpenseTrend(7);
});

/// Provider pemakaian memori penyimpanan (Database + Nota)
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  return await StorageService.getStorageUsage();
});
