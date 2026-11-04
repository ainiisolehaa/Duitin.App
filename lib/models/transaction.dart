/// Tipe transaksi: pemasukan atau pengeluaran.
enum TransactionType {
  income, // Pemasukan
  expense, // Pengeluaran
}

/// Model Transaction — mencatat setiap pemasukan/pengeluaran.
///
/// Setiap transaksi terhubung ke [userId] (foreign key ke tabel users)
/// dan memiliki kategori, jumlah uang, tanggal, dan catatan opsional.
class Transaction {
  final int? id;
  final int userId;
  final String category;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Konversi dari Map (hasil query SQLite) ke objek Transaction.
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type'] as int],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Konversi objek Transaction ke Map untuk disimpan ke SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'type': type.index, // 0 = income, 1 = expense
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Buat salinan Transaction dengan field yang diperbarui.
  Transaction copyWith({
    int? id,
    int? userId,
    String? category,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Helper: apakah ini transaksi pengeluaran?
  bool get isExpense => type == TransactionType.expense;

  /// Helper: apakah ini transaksi pemasukan?
  bool get isIncome => type == TransactionType.income;

  @override
  String toString() {
    return 'Transaction(id: $id, userId: $userId, category: $category, '
        'amount: $amount, type: ${type.name}, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
