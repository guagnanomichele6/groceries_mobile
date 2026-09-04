import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class InventoryService {
  // Recupera gli elementi della dispensa ordinati alfabeticamente
  static Future<List<Map<String, dynamic>>> getInventory() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('inventory', orderBy: 'item_name ASC');
  }

  // Aggiunge un articolo in dispensa
  static Future<void> addInventoryItem(
    String itemName,
    double quantity,
    String unit,
    String category,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('inventory', {
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'category': category,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Recupera la lista della spesa ordinata alfabeticamente
  static Future<List<Map<String, dynamic>>> getShoppingList() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('shopping_list', orderBy: 'item_name ASC');
  }

  // Aggiunge un articolo alla lista della spesa
  static Future<void> addShoppingItem(
    String itemName,
    double quantity,
    String unit,
    String category,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('shopping_list', {
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'checked': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
