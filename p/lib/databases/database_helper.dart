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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Drop and recreate tables for major changes
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS events');
      await db.execute('DROP TABLE IF EXISTS event_participants');
      await db.execute('DROP TABLE IF EXISTS favorites');
      await db.execute('DROP TABLE IF EXISTS session');
      await _createDB(db, newVersion);
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
        isEmailVerified INTEGER DEFAULT 0,
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

    // Events table with category and timestamps
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
        category $textNullable,
        createdBy $textNullable,
        createdAt $textType,
        eventDateTime TEXT
      )
    ''');
    
    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventId TEXT NOT NULL,
        userId TEXT NOT NULL,
        UNIQUE(eventId, userId)
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
    
    final emailCheck = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    
    if (emailCheck.isNotEmpty) {
      throw Exception('Email already exists');
    }

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
      'isEmailVerified': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return UserModel(
      id: userId,
      email: email.toLowerCase(),
      username: username,
      selectedCategories: [],
    );
  }

  Future<void> verifyUserEmail(String email) async {
    final db = await database;
    await db.update(
      'users',
      {'isEmailVerified': 1},
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
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

    Future<bool> checkUsernameExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }


  // ========== EVENT METHODS ==========
  
  Future<void> insertEvent(Event event, {String? userId}) async {
    final db = await database;
    await db.insert(
      'events',
      {
        ...event.toJson(),
        'category': event.category ?? '',
        'createdBy': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'eventDateTime': event.date,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
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

  Future<void> updateEvent(Event event) async {
    final db = await database;
    await db.update(
      'events',
      event.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  // ========== EVENT PARTICIPATION (JOIN) METHODS ==========
  
  Future<void> joinEvent(String eventId, String userId) async {
    final db = await database;
    
    // Check if already joined
    final existing = await db.query(
      'event_participants',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );

    if (existing.isNotEmpty) {
      throw Exception('Already joined this event');
    }

    // Insert participation record
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
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    final db = await database;
    
    final deleted = await db.delete(
      'event_participants',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );

    if (deleted > 0) {
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

  // Get user's joined events (upcoming and past)
  Future<List<Event>> getUserJoinedEvents(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM events e
      INNER JOIN event_participants ep ON e.id = ep.eventId
      WHERE ep.userId = ?
      ORDER BY e.eventDateTime DESC
    ''', [userId]);

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get user's created events
  Future<List<Event>> getUserCreatedEvents(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'createdBy = ?',
      whereArgs: [userId],
      orderBy: 'eventDateTime DESC',
    );

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get upcoming events (user joined + created, future dates)
  Future<List<Event>> getUserUpcomingEvents(String userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT e.* FROM events e
      LEFT JOIN event_participants ep ON e.id = ep.eventId
      WHERE (ep.userId = ? OR e.createdBy = ?)
      AND e.eventDateTime >= ?
      ORDER BY e.eventDateTime ASC
    ''', [userId, userId, now]);

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get past events (user joined + created, past dates)
  Future<List<Event>> getUserPastEvents(String userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT e.* FROM events e
      LEFT JOIN event_participants ep ON e.id = ep.eventId
      WHERE (ep.userId = ? OR e.createdBy = ?)
      AND e.eventDateTime < ?
      ORDER BY e.eventDateTime DESC
    ''', [userId, userId, now]);

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get popular events (sorted by attendees, limit for home screen)
  Future<List<Event>> getPopularEvents({int limit = 4}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'attendeesCount DESC, createdAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get all popular events for "See All" page
  Future<List<Event>> getAllPopularEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'attendeesCount DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get upcoming events based on user preferences (limit for home)
  Future<List<Event>> getUpcomingEventsByPreferences(List<String> categories, {int limit = 4}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    if (categories.isEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'eventDateTime >= ?',
        whereArgs: [now],
        orderBy: 'eventDateTime ASC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
    }

    final placeholders = categories.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM events 
      WHERE category IN ($placeholders) 
      AND eventDateTime >= ?
      ORDER BY eventDateTime ASC 
      LIMIT ?
    ''', [...categories, now, limit]);

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get all upcoming events for "See All"
  Future<List<Event>> getAllUpcomingEventsByPreferences(List<String> categories) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    if (categories.isEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'eventDateTime >= ?',
        whereArgs: [now],
        orderBy: 'eventDateTime ASC',
      );
      return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
    }

    final placeholders = categories.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM events 
      WHERE category IN ($placeholders)
      AND eventDateTime >= ?
      ORDER BY eventDateTime ASC
    ''', [...categories, now]);

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get recommended events (latest by preferences, limit for home)
  Future<List<Event>> getRecommendedEvents(List<String> categories, {int limit = 4}) async {
    final db = await database;
    
    if (categories.isEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
    }

    final placeholders = categories.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM events 
      WHERE category IN ($placeholders)
      ORDER BY createdAt DESC 
      LIMIT ?
    ''', [...categories, limit]);

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // Get all recommended events for "See All"
  Future<List<Event>> getAllRecommendedEvents(List<String> categories) async {
    final db = await database;
    
    if (categories.isEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        orderBy: 'createdAt DESC',
      );
      return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
    }

    final placeholders = categories.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM events 
      WHERE category IN ($placeholders)
      ORDER BY createdAt DESC
    ''', [...categories]);

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  // ========== FAVORITES METHODS ==========
  
  Future<void> addFavorite(String eventId, String userId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'eventId': eventId, 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}