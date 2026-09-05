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
}
