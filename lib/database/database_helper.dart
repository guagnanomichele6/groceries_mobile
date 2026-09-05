import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_food.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print("📍 PERCORSO ESATTO DEL DB: $path"); // <--- Aggiungi questa riga

    // ATTENZIONE: Durante lo sviluppo, se vuoi forzare la ricarica
    // del DB dagli asset a ogni avvio, decommenta la riga sotto:
    await deleteDatabase(path);

    bool exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      try {
        ByteData data = await rootBundle.load('assets/finance_food.db');
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        return await _createDB(path);
      }
    }

    return await openDatabase(path);
  }

  Future<Database> _createDB(String path) async {
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabelle standard del tuo ERP
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL NOT NULL,
            currency TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            account_id INTEGER,
            total_amount REAL NOT NULL,
            fee REAL DEFAULT 0.0,
            currency TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            category TEXT NOT NULL,
            checked INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE meals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE calendar_schedule (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            slot TEXT NOT NULL,
            meal_id INTEGER,
            context TEXT,
            consumed INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE investments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_name TEXT NOT NULL,
            category TEXT NOT NULL,
            account_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            current_value REAL NOT NULL,
            currency TEXT NOT NULL
          )
        ''');
      },
    );
    return db;
  }
}
