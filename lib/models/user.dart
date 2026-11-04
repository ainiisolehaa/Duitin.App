/// Model User — mewakili pengguna aplikasi Duitin.
///
/// Setiap pengguna memiliki nama, email (opsional), dan pengaturan
/// mata uang. Semua transaksi dan anggaran terhubung ke [userId].
/// Field [password] digunakan untuk autentikasi dummy lokal.
class User {
  final int? id;
  final String name;
  final String? email;
  final String? password; // hash sederhana untuk auth lokal
  final String currency; // default 'IDR'
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.name,
    this.email,
    this.password,
    this.currency = 'IDR',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Konversi dari Map (hasil query SQLite) ke objek User.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      password: map['password'] as String?,
      currency: map['currency'] as String? ?? 'IDR',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Konversi objek User ke Map untuk disimpan ke SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      'currency': currency,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Buat salinan User dengan field yang diperbarui.
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
