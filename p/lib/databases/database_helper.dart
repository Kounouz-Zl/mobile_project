import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';
import 'package:flutter/foundation.dart'; 


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
  
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE events (
        id $idType,
        title $textType,
        description $textType,
        location $textType,
        locationAddress $textType,
        date $textType,
        imageUrl $textType,
        organizerName $textType,
        organizerImageUrl $textType,
        attendeesCount $intType
      )
    ''');
     await db.execute('''
    CREATE TABLE events (
      id $idType,
      title $textType,
      description $textType,
      location $textType,
      locationAddress $textType,
      date $textType,
      imageUrl $textType,
      organizerName $textType,
      organizerImageUrl $textType,
      attendeesCount $intType
    )
  ''');
  
  // Favorites table
  await db.execute('''
    CREATE TABLE favorites (
      eventId TEXT PRIMARY KEY
    )
  ''');
  }

  Future<void> insertEvent(Event event) async {
    final db = await database;
    await db.insert(
      'events',
      event.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');

    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  Future<Event?> getEventById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Event.fromJson(maps.first);
  }

  Future<void> deleteEvent(String id) async {
    final db = await database;
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateEvent(Event event) async {
    final db = await database;
    await db.update(
      'events',
      event.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
  // Favorites methods
Future<void> addFavorite(String eventId) async {
  final db = await database;
  await db.insert(
    'favorites',
    {'eventId': eventId},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> removeFavorite(String eventId) async {
  final db = await database;
  await db.delete(
    'favorites',
    where: 'eventId = ?',
    whereArgs: [eventId],
  );
}

Future<List<String>> getAllFavorites() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query('favorites');
  return List.generate(maps.length, (i) => maps[i]['eventId'] as String);
}

Future<bool> isFavorite(String eventId) async {
  final db = await database;
  final result = await db.query(
    'favorites',
    where: 'eventId = ?',
    whereArgs: [eventId],
  );
  return result.isNotEmpty;
}
  
}
