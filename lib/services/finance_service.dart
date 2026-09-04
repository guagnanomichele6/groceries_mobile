import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class FinanceService {
  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('accounts', orderBy: 'name ASC');
  }

  static Future<void> addAccount(
    String name,
    String type,
    double balance,
    String currency,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('accounts', {
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- TRANSACTIONS ---

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT t.*, a.name as account_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      ORDER BY t.date DESC
    ''');
  }

  static Future<void> addTransaction({
    required String date,
    required int accountId,
    required double amount, // Positivo per entrata, negativo per spesa
    required String category,
    required String description,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // 1. Inserisci la transazione
      await txn.insert('transactions', {
        'date': date,
        'account_id': accountId,
        'total_amount': amount,
        'currency': 'EUR',
        'category': category,
        'description': description,
      });

      // 2. Aggiorna il saldo del conto corrispondente
      await txn.rawUpdate(
        '''
        UPDATE accounts 
        SET balance = balance + ? 
        WHERE id = ?
      ''',
        [amount, accountId],
      );
    });
  }
}
