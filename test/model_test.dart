import 'package:flutter_test/flutter_test.dart';
import 'package:duitin/models/user.dart';
import 'package:duitin/models/transaction.dart';
import 'package:duitin/models/budget.dart';

/// Unit test untuk model Duitin.
///
/// Tes ini memvalidasi serialisasi (toMap/fromMap) dan copyWith
/// tanpa memerlukan emulator atau perangkat fisik.
///
/// Jalankan dengan: flutter test test/model_test.dart
void main() {
  group('User Model', () {
    test('toMap dan fromMap menghasilkan objek yang konsisten', () {
      final user = User(
        id: 1,
        name: 'Budi',
        email: 'budi@email.com',
        currency: 'IDR',
      );

      final map = user.toMap();
      final restored = User.fromMap(map);

      expect(restored.id, equals(1));
      expect(restored.name, equals('Budi'));
      expect(restored.email, equals('budi@email.com'));
      expect(restored.currency, equals('IDR'));
    });

    test('copyWith mengubah field yang ditentukan', () {
      final user = User(id: 1, name: 'Budi');
      final updated = user.copyWith(name: 'Andi', email: 'andi@email.com');

      expect(updated.name, equals('Andi'));
      expect(updated.email, equals('andi@email.com'));
      expect(updated.id, equals(1)); // tidak berubah
    });

    test('default currency adalah IDR', () {
      final user = User(name: 'Test');
      expect(user.currency, equals('IDR'));
    });
  });

  group('Transaction Model', () {
    test('toMap dan fromMap menghasilkan objek yang konsisten', () {
      final now = DateTime.now();
      final tx = Transaction(
        id: 1,
        userId: 1,
        category: 'Makan',
        amount: 25000,
        type: TransactionType.expense,
        date: now,
        note: 'Nasi goreng',
      );

      final map = tx.toMap();
      final restored = Transaction.fromMap(map);

      expect(restored.id, equals(1));
      expect(restored.userId, equals(1));
      expect(restored.category, equals('Makan'));
      expect(restored.amount, equals(25000));
      expect(restored.type, equals(TransactionType.expense));
      expect(restored.note, equals('Nasi goreng'));
      expect(restored.isExpense, isTrue);
      expect(restored.isIncome, isFalse);
    });

    test('type.index menyimpan 0 untuk income, 1 untuk expense', () {
      expect(TransactionType.income.index, equals(0));
      expect(TransactionType.expense.index, equals(1));
    });

    test('copyWith mengubah amount dan category', () {
      final tx = Transaction(
        userId: 1,
        category: 'Makan',
        amount: 25000,
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      final updated = tx.copyWith(amount: 30000, category: 'Transport');

      expect(updated.amount, equals(30000));
      expect(updated.category, equals('Transport'));
      expect(updated.type, equals(TransactionType.expense)); // tidak berubah
    });
  });

  group('Budget Model', () {
    test('toMap dan fromMap menghasilkan objek yang konsisten', () {
      final budget = Budget(
        id: 1,
        userId: 1,
        category: 'Makan',
        amount: 1500000,
        month: 11,
        year: 2026,
      );

      final map = budget.toMap();
      final restored = Budget.fromMap(map);

      expect(restored.id, equals(1));
      expect(restored.userId, equals(1));
      expect(restored.category, equals('Makan'));
      expect(restored.amount, equals(1500000));
      expect(restored.month, equals(11));
      expect(restored.year, equals(2026));
    });

    test('copyWith mengubah amount', () {
      final budget = Budget(
        userId: 1,
        category: 'Transport',
        amount: 500000,
        month: 11,
        year: 2026,
      );

      final updated = budget.copyWith(amount: 750000);

      expect(updated.amount, equals(750000));
      expect(updated.category, equals('Transport')); // tidak berubah
    });
  });
}

