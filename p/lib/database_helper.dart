
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'models/event.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'events.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        location TEXT NOT NULL,
        date TEXT NOT NULL,
        price TEXT NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites(
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events(id)
      )
    ''');
  }

  Future<void> insertEvent(Event event) async {
    final db = await database;
    await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Event>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  Future<void> insertFavorite(String eventId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'eventId': eventId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFavorite(String eventId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  Future<bool> isFavorite(String eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
    return maps.isNotEmpty;
  }

  Future<List<String>> getFavoriteEventIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) {
      return maps[i]['eventId'];
    });
  }
}
