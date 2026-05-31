import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/debt.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hanout.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Table Products (Zidna priceSell hna)
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        barcode TEXT,
        name TEXT,
        brand TEXT,
        category TEXT,
        imageUrl TEXT,
        supplierDefault TEXT,
        priceInit REAL,
        priceSell REAL,  -- column jdid
        currentQuantity INTEGER,
        minAlertQuantity INTEGER,
        isSynced INTEGER DEFAULT 1
      )
    ''');

    // 2. Table Sales Offline
    await db.execute('''
      CREATE TABLE sales_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        items TEXT,
        paymentMethod TEXT,
        customerName TEXT,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // 3. Table Debts Offline
    await db.execute('''
      CREATE TABLE debts_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT,
        phoneNumber TEXT,
        totalDebt REAL,
        paidAmount REAL,
        remainingAmount REAL,
        isSynced INTEGER DEFAULT 0
      )
    ''');
  }

  // ==================== FONCTIONS PRODUCTS ====================

  Future<void> saveProducts(List<Product> products) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var p in products) {
      batch.insert(
        'products',
        p.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveSingleProduct(Product product, {int isSynced = 1}) async {
    final db = await instance.database;
    Map<String, dynamic> data = product.toLocalMap();
    data['isSynced'] = isSynced;
    if (data['id'] == null) data['id'] = "off_${product.barcode}";
    await db.insert(
      'products',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getLocalProducts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromLocalMap(maps[i]));
  }

  Future<void> decrementLocalStock(String productId, int quantity) async {
    final db = await instance.database;
    await db.execute(
      'UPDATE products SET currentQuantity = currentQuantity - ? WHERE id = ?',
      [quantity, productId],
    );
  }

  // ==================== FONCTIONS SALES & DEBTS (OFFLINE) ====================

  Future<void> insertOfflineSale(Map<String, dynamic> sale) async {
    final db = await instance.database;
    await db.insert('sales_offline', sale);
  }

  Future<void> saveDebts(List<Debt> debts) async {
    final db = await instance.database;
    final batch = db.batch();
    await db.delete('debts_offline', where: 'isSynced = 1');
    for (var d in debts) {
      batch.insert('debts_offline', {
        'customerName': d.customerName,
        'phoneNumber': d.phoneNumber,
        'totalDebt': d.totalDebt,
        'paidAmount': d.paidAmount,
        'remainingAmount': d.remainingAmount,
        'isSynced': 1,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Debt>> getLocalDebts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('debts_offline');
    return List.generate(maps.length, (i) => Debt.fromLocalMap(maps[i]));
  }

  Future<void> saveSingleDebtOffline(Debt debt, {int isSynced = 0}) async {
    final db = await instance.database;
    await db.insert('debts_offline', {
      'customerName': debt.customerName,
      'phoneNumber': debt.phoneNumber,
      'totalDebt': debt.totalDebt,
      'paidAmount': debt.paidAmount,
      'remainingAmount': debt.remainingAmount,
      'isSynced': isSynced,
    });
  }

  Future<void> insertOfflineDebt(Map<String, dynamic> debt) async {
    final db = await instance.database;
    await db.insert(
      'debts_offline',
      debt,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
