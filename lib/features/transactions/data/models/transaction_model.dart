class TransactionModel {
  final int? id;
  final String type; // 'INCOME' or 'EXPENSE'
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final String? receiptImagePath;
  final int? receiptSizeBytes;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.receiptImagePath,
    this.receiptSizeBytes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? date;

  bool get isIncome => type.toUpperCase() == 'INCOME';
  bool get isExpense => type.toUpperCase() == 'EXPENSE';
  bool get hasReceipt => receiptImagePath != null && receiptImagePath!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'receipt_image_path': receiptImagePath,
      'receipt_size_bytes': receiptSizeBytes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
      receiptImagePath: map['receipt_image_path'] as String?,
      receiptSizeBytes: map['receipt_size_bytes'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? receiptImagePath,
    int? receiptSizeBytes,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      receiptSizeBytes: receiptSizeBytes ?? this.receiptSizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
