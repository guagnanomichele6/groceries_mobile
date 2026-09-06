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
    // Eseguiamo una JOIN per prendere la valuta e il nome del conto associato
    final result = await db.rawQuery('''
      SELECT t.*, a.name as account_name, a.currency as currency
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      ORDER BY t.date DESC
    ''');
    return result;
  }

  static Future<void> addTransaction({
    required String date,
    required int accountId,
    required double amount,
    double fee = 0.0,
    required String category,
    required String description,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Impatto totale sul conto (Importo + Fee)
    double totalImpact = amount < 0
        ? amount - fee
        : amount -
              fee; // se spesa sottrae importo e fee, se entrata sottrae la fee

    await db.transaction((txn) async {
      await txn.insert('transactions', {
        'date': date,
        'account_id': accountId,
        'total_amount': amount,
        'fee': fee,
        'category': category,
        'description': description,
      });

      // Aggiorna il saldo del conto
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [
          amount < 0 ? (amount - fee) : (amount - fee),
          accountId,
        ], // gestisci il segno coerentemente
      );
    });
  }

  static Future<void> executeTransfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    double fee = 0.0,
    required String note,
  }) async {
    final db = await DatabaseHelper.instance.database;
    String dateStr = DateTime.now().toIso8601String().substring(0, 10);

    await db.transaction((txn) async {
      // 1. Scala dal conto mittente (Importo + Fee)
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount + fee, fromAccountId],
      );
      // 2. Aggiunge al conto destinatario
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, toAccountId],
      );
      // 3. Registra la transazione di giroconto
      await txn.insert('transactions', {
        'date': dateStr,
        'account_id': fromAccountId,
        'total_amount': -amount,
        'fee': fee,
        'category': 'Giroconto',
        'description': note,
      });
    });
  }

  static Future<void> deleteTransaction(int transactionId) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // 1. Recupera i dati della transazione prima di eliminarla
      final List<Map<String, dynamic>> results = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (results.isNotEmpty) {
        final tx = results.first;
        int accountId = tx['account_id'];
        double amount = tx['total_amount'];
        double fee = tx['fee'] ?? 0.0;

        // 2. Calcola l'impatto da stornare (inverte l'operazione fatta al momento dell'inserimento)
        // Se total_amount era negativo (spesa), dobbiamo restituire l'importo e la fee al saldo.
        // Se era positivo (entrata), dobbiamo sottrarre l'importo dal saldo.
        double refundAmount = amount < 0 ? (-amount + fee) : (amount - fee);
        String updateQuery = amount < 0
            ? 'UPDATE accounts SET balance = balance + ? WHERE id = ?'
            : 'UPDATE accounts SET balance = balance - ? WHERE id = ?';

        // 3. Aggiorna il saldo del conto
        await txn.rawUpdate(updateQuery, [refundAmount, accountId]);

        // 4. Elimina la transazione
        await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [transactionId],
        );
      }
    });
  }
}
