import 'package:flutter_test/flutter_test.dart';
import 'package:sakubuku/core/utils/currency_formatter.dart';
import 'package:sakubuku/features/transactions/data/models/transaction_model.dart';

void main() {
  group('Unit Tests: SakuBuku Core Engine', () {
    test('CurrencyFormatter formats Rupiah correctly', () {
      expect(CurrencyFormatter.formatRupiah(150000), 'Rp 150.000');
      expect(CurrencyFormatter.formatRupiah(0), 'Rp 0');
      expect(CurrencyFormatter.formatWithSign(50000, 'EXPENSE'), '-Rp 50.000');
      expect(CurrencyFormatter.formatWithSign(100000, 'INCOME'), '+Rp 100.000');
    });

    test('CurrencyFormatter parseRaw handles clean numeric conversion', () {
      expect(CurrencyFormatter.parseRaw('Rp 250.000'), 250000.0);
      expect(CurrencyFormatter.parseRaw('50000'), 50000.0);
      expect(CurrencyFormatter.parseRaw('abc'), 0.0);
    });

    test('TransactionModel toMap and fromMap serialization integrity', () {
      final now = DateTime.now();
      final item = TransactionModel(
        id: 1,
        type: 'EXPENSE',
        amount: 35000.0,
        category: 'Makanan & Minuman',
        date: now,
        note: 'Nasi Padang',
        receiptImagePath: '/data/user/0/com.sakubuku/receipts/test.webp',
        receiptSizeBytes: 75400,
      );

      final map = item.toMap();
      expect(map['id'], 1);
      expect(map['type'], 'EXPENSE');
      expect(map['amount'], 35000.0);
      expect(map['category'], 'Makanan & Minuman');
      expect(map['receipt_size_bytes'], 75400);

      final parsed = TransactionModel.fromMap(map);
      expect(parsed.id, item.id);
      expect(parsed.type, item.type);
      expect(parsed.amount, item.amount);
      expect(parsed.category, item.category);
      expect(parsed.receiptImagePath, item.receiptImagePath);
      expect(parsed.receiptSizeBytes, item.receiptSizeBytes);
      expect(parsed.isExpense, true);
      expect(parsed.isIncome, false);
      expect(parsed.hasReceipt, true);
    });
  });
}
