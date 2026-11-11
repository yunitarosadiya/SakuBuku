import '../../../../core/database/database_helper.dart';
import '../../../../core/services/storage_service.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _db;

  TransactionRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<int> addTransaction(TransactionModel item) async {
    return await _db.insertTransaction(item);
  }

  Future<int> updateTransaction(TransactionModel item) async {
    return await _db.updateTransaction(item);
  }

  Future<int> deleteTransaction(int id) async {
    // Cari transaksi untuk mengetahui apakah ada nota terlampir
    final item = await _db.getTransactionById(id);
    if (item?.receiptImagePath != null) {
      await StorageService.deleteReceiptFile(item!.receiptImagePath);
    }
    return await _db.deleteTransaction(id);
  }

  Future<List<TransactionModel>> getAllTransactions({int? limit, int? offset}) async {
    return await _db.getAllTransactions(limit: limit, offset: offset);
  }

  Future<List<TransactionModel>> getTodayTransactions() async {
    return await _db.getTransactionsToday();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month) async {
    return await _db.getTransactionsByMonth(year, month);
  }

  Future<Map<String, double>> getBalanceSummary() async {
    return await _db.getTotalBalanceSummary();
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    return await _db.getMonthlySummary(year, month);
  }

  Future<List<Map<String, dynamic>>> getDailyExpenseTrend(int days) async {
    return await _db.getDailyExpenseTrend(days);
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown(int year, int month, {String type = 'EXPENSE'}) async {
    return await _db.getCategoryBreakdown(year: year, month: month, type: type);
  }

  Future<void> clearAllData() async {
    // Hapus file-file nota
    try {
      final dir = await StorageService.getReceiptsDirectory();
      if (await dir.exists()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
    await _db.clearAllData();
  }
}
