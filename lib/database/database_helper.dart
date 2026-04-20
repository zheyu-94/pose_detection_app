import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fitness_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // 根據妳的 ERD 圖建立資料表
  Future<void> _onCreate(Database db, int version) async {
    // 使用者表
    await db.execute('''
      CREATE TABLE user(
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        height REAL,
        weight REAL,
        age INTEGER
      )
    ''');

    // 訓練紀錄表
    await db.execute('''
      CREATE TABLE workoutlog(
        log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        exercise_id INTEGER,
        rep INTEGER,
        sets INTEGER,
        timestamp TEXT
      )
    ''');
  }

  // 新增紀錄的方法
  Future<int> insertWorkout(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('workoutlog', row);
  }
}