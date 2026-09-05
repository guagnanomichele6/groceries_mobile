import '../database/database_helper.dart';

class RecurringService {
  // Recupera tutti i modelli ricorrenti con il nome del conto associato
  static Future<List<Map<String, dynamic>>> getRecurringExpenses() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT r.*, a.name AS account_name 
      FROM recurring_expenses r 
      LEFT JOIN accounts a ON r.account_id = a.id
    ''');
  }

  // Aggiunge un nuovo modello ricorrente
  static Future<void> addRecurringExpense({
    required String name,
    required int accountId,
    required double amount,
    required String currency,
    required String frequency,
    required String intervalValue,
    required String category,
    required String opType,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('recurring_expenses', {
      'name': name,
      'account_id': accountId,
      'amount': amount,
      'currency': currency,
      'frequency': frequency,
      'interval_value': intervalValue,
      'category': category,
      'op_type': opType,
    });
  }

  // Elimina un modello ricorrente
  static Future<void> deleteRecurringExpense(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('recurring_expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Esegue il pagamento/incasso del modello ricorrente (crea la transazione e aggiorna il saldo)
  static Future<void> executeRecurring({
    required int recurringId,
    required String name,
    required int accountId,
    required double amount,
    required String currency,
    required String category,
    required String opType,
    required String dateStr,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Aggiorna il conto (se Spesa scala, se Entrata aggiunge)
      if (opType == 'Spesa') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [amount, accountId],
        );
      } else {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, accountId],
        );
      }

      // Registra la transazione effettiva
      double finalAmount = opType == 'Spesa' ? -amount : amount;
      await txn.insert('transactions', {
        'date': dateStr,
        'account_id': accountId,
        'total_amount': finalAmount,
        'fee': 0.0,
        'currency': currency,
        'category': category,
        'description': 'Ricorrente ($opType): $name',
      });
    });
  }
}
