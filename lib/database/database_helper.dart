import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Metodo per sostituire/aggiornare il database (es. importato da PC)
  Future<void> replaceDatabase(String newFilePath) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'finance_food.db');

    // 1. Chiudi la connessione attiva se esiste
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // 2. Copia il nuovo file sovrascrivendo quello vecchio nei Documents
    File sourceFile = File(newFilePath);
    await sourceFile.copy(path);
  }

  Future<Database> get database async {
    // Se c'è già una connessione aperta, la chiudiamo per forzare la rilettura dal disco
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _database = await _initDB('finance_food.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print("📍 PERCORSO ESATTO DEL DB: $path");

    bool exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Se il database non esiste nei Documents, lo crea da zero con tutte le tabelle
      return await _createDB(path);
    }

    // Se esiste già, lo apre normalmente (rileggendo le modifiche o il file sostituito)
    return await openDatabase(path);
  }

  Future<Database> _createDB(String path) async {
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabelle standard complete del tuo ERP
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
