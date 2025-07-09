import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // FFI untuk desktop
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/financial_transaction_model.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Inisialisasi database
    _database = await _initDatabase();
    return _database!;
  }

  // Inisialisasi database SQLite
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kas_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            type TEXT,
            amount REAL,
            description TEXT,
            date TEXT,
            FOREIGN KEY (userId) REFERENCES users(id)
          )
        ''');
      },
    );
  }

  // Fungsi untuk mengecek apakah username sudah ada
  Future<bool> doesUsernameExist(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    return result.isNotEmpty;
  }

  // Fungsi untuk menambahkan user
  Future<void> insertUser(User user) async {
    final db = await database;

    final usernameExists = await doesUsernameExist(user.username);
    if (usernameExists) {
      throw Exception('Username Sudah Tersedia');
    }

    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fungsi untuk mendapatkan user berdasarkan username dan password
  Future<User?> getUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Fungsi untuk mendapatkan transaksi berdasarkan userId
  Future<List<FinancialTransaction>> getTransactions(int userId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return result.map((e) => FinancialTransaction.fromMap(e)).toList();
  }

  // Fungsi untuk mendapatkan transaksi berdasarkan ID
  Future<FinancialTransaction?> getTransactionById(int transactionId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (result.isNotEmpty) {
      return FinancialTransaction.fromMap(result.first);
    }
    return null;
  }

  // Fungsi untuk menambahkan transaksi
  Future<void> insertTransaction(FinancialTransaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fungsi untuk mengedit transaksi berdasarkan ID
  Future<void> updateTransaction(FinancialTransaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?', // Mengupdate berdasarkan ID transaksi
      whereArgs: [transaction.id],
    );
  }

  // Fungsi untuk menghapus transaksi berdasarkan ID
  Future<void> deleteTransaction(int transactionId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Fungsi untuk menghapus semua transaksi berdasarkan userId
  Future<void> clearTransactions(int userId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}
