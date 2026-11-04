/// Model Budget — anggaran bulanan per kategori.
///
/// Setiap budget terhubung ke [userId] dan berlaku untuk [month]/[year]
/// tertentu. Berguna untuk membandingkan pengeluaran aktual vs anggaran.
class Budget {
  final int? id;
  final int userId;
  final String category;
  final double amount;       // Batas anggaran
  final int month;           // 1-12
  final int year;            // e.g. 2026
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Konversi dari Map (hasil query SQLite) ke objek Budget.
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Konversi objek Budget ke Map untuk disimpan ke SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Buat salinan Budget dengan field yang diperbarui.
  Budget copyWith({
    int? id,
    int? userId,
    String? category,
    double? amount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, userId: $userId, category: $category, '
        'amount: $amount, month: $month, year: $year)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

