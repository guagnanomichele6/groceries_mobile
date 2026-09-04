import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        // Abilita le foreign key in SQLite
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // --- 1. FINANCE MODULE ---
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EUR'
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        account_id INTEGER,
        total_amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EUR',
        category TEXT NOT NULL DEFAULT 'Spesa',
        description TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        account_id INTEGER,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EUR',
        frequency TEXT NOT NULL DEFAULT 'Mensile',
        interval_value TEXT NOT NULL DEFAULT '1',
        category TEXT NOT NULL DEFAULT 'Bollette',
        op_type TEXT NOT NULL DEFAULT 'Spesa',
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // --- 2. POSSESSIONS & INVENTORY MODULE ---
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Dispensa',
        quantity REAL NOT NULL,
        unit TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Dispensa',
        checked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE global_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_name TEXT UNIQUE NOT NULL,
        unit_type TEXT NOT NULL,
        to_base_multiplier REAL NOT NULL DEFAULT 1.0
      )
    ''');

    // Inserimento unità di misura di default
    final defaultUnits = [
      {'unit_name': 'grammi', 'unit_type': 'peso', 'to_base_multiplier': 1.0},
      {'unit_name': 'kg', 'unit_type': 'peso', 'to_base_multiplier': 1000.0},
      {'unit_name': 'ml', 'unit_type': 'volume', 'to_base_multiplier': 1.0},
      {
        'unit_name': 'litri',
        'unit_type': 'volume',
        'to_base_multiplier': 1000.0,
      },
      {'unit_name': 'pezzi', 'unit_type': 'pezzo', 'to_base_multiplier': 1.0},
      {'unit_name': 'bustine', 'unit_type': 'pezzo', 'to_base_multiplier': 1.0},
      {
        'unit_name': 'cucchiai',
        'unit_type': 'altro',
        'to_base_multiplier': 1.0,
      },
      {
        'unit_name': 'confezioni',
        'unit_type': 'pezzo',
        'to_base_multiplier': 1.0,
      },
    ];

    for (var unit in defaultUnits) {
      await db.insert(
        'global_units',
        unit,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // --- 3. MEALS & KITCHEN MODULE ---
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calendar_schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        slot TEXT NOT NULL,
        meal_id INTEGER,
        context TEXT NOT NULL DEFAULT 'A Casa (Canonico)',
        consumed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calendar_slot_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES calendar_schedule (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE investments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'ETF',
        account_name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0.0,
        current_value REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'EUR'
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
