import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class KitchenService {
  // Recupera tutti i piatti salvati ordinati alfabeticamente
  static Future<List<Map<String, dynamic>>> getMeals() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('meals', orderBy: 'name ASC');
  }

  // Aggiunge un nuovo piatto
  static Future<int> addMeal(String name) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('meals', {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Recupera la pianificazione del calendario ordinata per data
  static Future<List<Map<String, dynamic>>> getCalendarSchedule() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT cs.*, m.name as meal_name 
      FROM calendar_schedule cs
      LEFT JOIN meals m ON cs.meal_id = m.id
      ORDER BY cs.date DESC, cs.slot ASC
    ''');
  }

  // Aggiorna lo stato di consumo di uno slot nel calendario (es. 0 o 1)
  static Future<void> toggleConsumed(int scheduleId, int consumedStatus) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'calendar_schedule', // Sostituisci con il nome esatto della tua tabella se diverso
      {'consumed': consumedStatus},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  // Elimina uno slot pianificato dal calendario
  static Future<void> deleteScheduleSlot(int scheduleId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'calendar_schedule', // Sostituisci con il nome esatto della tua tabella se diverso
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  // Inserisce un nuovo slot pianificato nel calendario della cucina
  static Future<void> addCalendarSchedule({
    required String date,
    required String slot,
    required int mealId,
    required String context,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('calendar_schedule', {
      // Sostituisci con il nome esatto della tua tabella se diverso
      'date': date,
      'slot': slot,
      'meal_id': mealId,
      'context': context,
      'consumed': 0, // Di default non consumato
    });
  }

  // Recupera gli elementi della dispensa
  static Future<List<Map<String, dynamic>>> getPantryItems() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'pantry',
    ); // Sostituisci 'pantry' con il nome esatto della tua tabella se diverso
  }

  // Aggiunge un articolo alla dispensa
  static Future<void> addPantryItem({
    required String name,
    required double quantity,
    required String unit,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('pantry', {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    });
  }

  // Rimuove un articolo dalla dispensa
  static Future<void> deletePantryItem(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('pantry', where: 'id = ?', whereArgs: [id]);
  }

  // Aggiunge un pasto al calendario
  static Future<void> scheduleMeal({
    required String date,
    required String slot,
    required int mealId,
    required String context,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('calendar_schedule', {
      'date': date,
      'slot': slot,
      'meal_id': mealId,
      'context': context,
      'consumed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getInventoryItems() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('pantry'); // o il nome effettivo della tabella nel db
  }

  static Future<void> addInventoryItem(
    String name,
    double quantity,
    String unit,
    String category,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('pantry', {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
    });
  }

  static Future<void> deleteInventoryItem(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('pantry', where: 'id = ?', whereArgs: [id]);
  }
}
