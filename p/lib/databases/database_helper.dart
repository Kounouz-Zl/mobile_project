import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';
import '../models/user_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          email TEXT UNIQUE NOT NULL,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          profilePhotoUrl TEXT,
          selectedCategories TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password $textType,
        profilePhotoUrl $textNullable,
        selectedCategories $textNullable,
        createdAt $textType
      )
    ''');

    // Session table
    await db.execute('''
      CREATE TABLE session (
        id INTEGER PRIMARY KEY,
        userId TEXT NOT NULL,
        loginTime TEXT NOT NULL
      )
    ''');

    // Events table
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
        attendeesCount $intType,
        category $textNullable
      )
    ''');
    
    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        eventId TEXT PRIMARY KEY,
        userId TEXT NOT NULL
      )
    ''');

    // Event participants table
    await db.execute('''
      CREATE TABLE event_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventId TEXT NOT NULL,
        userId TEXT NOT NULL,
        joinedAt TEXT NOT NULL,
        UNIQUE(eventId, userId)
      )
    ''');
  }

  // Hash password
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ========== USER METHODS ==========
  
  Future<UserModel?> registerUser({
    required String email,
    required String username,
    required String password,
  }) async {
    final db = await database;
    
    // Check if email exists
    final emailCheck = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    
    if (emailCheck.isNotEmpty) {
      throw Exception('Email already exists');
    }

    // Check if username exists
    final usernameCheck = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.toLowerCase()],
    );
    
    if (usernameCheck.isNotEmpty) {
      throw Exception('Username already taken');
    }

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final hashedPassword = _hashPassword(password);

    await db.insert('users', {
      'id': userId,
      'email': email.toLowerCase(),
      'username': username.toLowerCase(),
      'password': hashedPassword,
      'profilePhotoUrl': null,
      'selectedCategories': '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    return UserModel(
      id: userId,
      email: email.toLowerCase(),
      username: username,
      selectedCategories: [],
    );
  }

  Future<UserModel?> loginUser(String usernameOrEmail, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);

    final results = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password = ?',
      whereArgs: [usernameOrEmail.toLowerCase(), usernameOrEmail.toLowerCase(), hashedPassword],
    );

    if (results.isEmpty) {
      throw Exception('Invalid username/email or password');
    }

    final userData = results.first;
    
    // Save session
    await db.delete('session');
    await db.insert('session', {
      'userId': userData['id'],
      'loginTime': DateTime.now().toIso8601String(),
    });

    return UserModel(
      id: userData['id'] as String,
      email: userData['email'] as String,
      username: userData['username'] as String,
      profilePhotoUrl: userData['profilePhotoUrl'] as String?,
      selectedCategories: (userData['selectedCategories'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final db = await database;
    
    final sessionResults = await db.query('session', limit: 1);
    
    if (sessionResults.isEmpty) {
      return null;
    }

    final userId = sessionResults.first['userId'] as String;
    
    final userResults = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (userResults.isEmpty) {
      return null;
    }

    final userData = userResults.first;
    
    return UserModel(
      id: userData['id'] as String,
      email: userData['email'] as String,
      username: userData['username'] as String,
      profilePhotoUrl: userData['profilePhotoUrl'] as String?,
      selectedCategories: (userData['selectedCategories'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
    );
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete('session');
  }

  Future<UserModel> updateUsername(String userId, String newUsername) async {
    final db = await database;
    
    // Check if username is already taken
    final existing = await db.query(
      'users',
      where: 'username = ? AND id != ?',
      whereArgs: [newUsername.toLowerCase(), userId],
    );

    if (existing.isNotEmpty) {
      throw Exception('Username already taken');
    }

    await db.update(
      'users',
      {'username': newUsername.toLowerCase()},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return (await getUserById(userId))!;
  }

  Future<UserModel> updateProfilePhoto(String userId, String photoUrl) async {
    final db = await database;
    
    await db.update(
      'users',
      {'profilePhotoUrl': photoUrl},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return (await getUserById(userId))!;
  }

  Future<UserModel> updateCategories(String userId, List<String> categories) async {
    final db = await database;
    
    await db.update(
      'users',
      {'selectedCategories': categories.join(',')},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return (await getUserById(userId))!;
  }

  Future<UserModel?> getUserById(String userId) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;

    final userData = results.first;
    
    return UserModel(
      id: userData['id'] as String,
      email: userData['email'] as String,
      username: userData['username'] as String,
      profilePhotoUrl: userData['profilePhotoUrl'] as String?,
      selectedCategories: (userData['selectedCategories'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
    );
  }

  Future<bool> checkUsernameExists(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.toLowerCase()],
    );
    return results.isNotEmpty;
  }

  Future<bool> checkEmailExists(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    return results.isNotEmpty;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw Exception('Email not found');
    }

    final hashedPassword = _hashPassword(newPassword);
    
    await db.update(
      'users',
      {'password': hashedPassword},
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  // ========== EVENT METHODS ==========
  
  Future<void> insertEvent(Event event) async {
    final db = await database;
    await db.insert(
      'events',
      {
        ...event.toJson(),
        'category': event.category ?? '',
      },
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

  // ========== EVENT PARTICIPATION METHODS ==========
  
  Future<void> joinEvent(String eventId, String userId) async {
    final db = await database;
    
    try {
      await db.insert('event_participants', {
        'eventId': eventId,
        'userId': userId,
        'joinedAt': DateTime.now().toIso8601String(),
      });

      // Increment attendees count
      await db.rawUpdate(
        'UPDATE events SET attendeesCount = attendeesCount + 1 WHERE id = ?',
        [eventId],
      );
    } catch (e) {
      // Already joined
      throw Exception('Already joined this event');
    }
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    final db = await database;
    
    final deleted = await db.delete(
      'event_participants',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );

    if (deleted > 0) {
      // Decrement attendees count
      await db.rawUpdate(
        'UPDATE events SET attendeesCount = MAX(0, attendeesCount - 1) WHERE id = ?',
        [eventId],
      );
    }
  }

  Future<bool> isUserJoinedEvent(String eventId, String userId) async {
    final db = await database;
    final results = await db.query(
      'event_participants',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );
    return results.isNotEmpty;
  }

  Future<List<Event>> getPopularEvents({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'attendeesCount DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  Future<List<Event>> getUpcomingEvents(List<String> userCategories, {int limit = 10}) async {
    final db = await database;
    
    if (userCategories.isEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        orderBy: 'date ASC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
    }

    final placeholders = userCategories.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM events WHERE category IN ($placeholders) ORDER BY date ASC LIMIT ?',
      [...userCategories, limit],
    );

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  Future<List<Event>> getRecommendedEvents(List<String> userCategories, {int limit = 10}) async {
    final db = await database;
    
    if (userCategories.isEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        orderBy: 'date DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
    }

    final placeholders = userCategories.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM events WHERE category IN ($placeholders) ORDER BY date DESC LIMIT ?',
      [...userCategories, limit],
    );

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // ========== FAVORITES METHODS ==========
  
  Future<void> addFavorite(String eventId, String userId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'eventId': eventId, 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(String eventId, String userId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );
  }

  Future<List<String>> getUserFavorites(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => maps[i]['eventId'] as String);
  }

  Future<bool> isFavorite(String eventId, String userId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );
    return result.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}