import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class InvestmentService {
  // Recupera tutti gli asset di investimento ordinati per nome
  static Future<List<Map<String, dynamic>>> getInvestments() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('investments', orderBy: 'asset_name ASC');
  }

  // Elimina un investimento
  static Future<void> deleteInvestment(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }

  // Aggiunge o aggiorna un asset nel portafoglio (stile statico/manuale)
  static Future<void> saveInvestment({
    required String assetName,
    required String category,
    required String accountName,
    required double quantity,
    required double currentValue,
    required String currency,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('investments', {
      'asset_name': assetName,
      'category': category,
      'account_name': accountName,
      'quantity': quantity,
      'current_value': currentValue,
      'currency': currency,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
