import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';
import '../models/user_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS events');
      await db.execute('DROP TABLE IF EXISTS event_participants');
      await db.execute('DROP TABLE IF EXISTS favorites');
      await db.execute('DROP TABLE IF EXISTS session');
      await db.execute('DROP TABLE IF EXISTS organizer_requests');
      await db.execute('DROP TABLE IF EXISTS event_registrations');
      await _createDB(db, newVersion);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password $textType,
        profilePhotoUrl $textNullable,
        selectedCategories $textNullable,
        isEmailVerified INTEGER DEFAULT 0,
        createdAt $textType,
        role TEXT DEFAULT 'participant'
      )
    ''');

    await db.execute('''
      CREATE TABLE session (
        id INTEGER PRIMARY KEY,
        userId TEXT NOT NULL,
        loginTime TEXT NOT NULL
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
        attendeesCount $intType,
        category $textNullable,
        createdBy $textNullable,
        createdAt $textType,
        eventDateTime TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventId TEXT NOT NULL,
        userId TEXT NOT NULL,
        UNIQUE(eventId, userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE event_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventId TEXT NOT NULL,
        userId TEXT NOT NULL,
        joinedAt TEXT NOT NULL,
        UNIQUE(eventId, userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE event_registrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        reason TEXT NOT NULL,
        registeredAt TEXT NOT NULL,
        status TEXT DEFAULT 'registered',
        UNIQUE(eventId, userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE organizer_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        organizationName TEXT NOT NULL,
        socialMediaLink TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        requestedAt TEXT NOT NULL,
        approvedAt TEXT,
        UNIQUE(userId)
      )
    ''');
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }


  DateTime? _parseEventDate(String dateString) {
  try {
    // Handle multiple date formats
    final formats = [
      DateFormat('dd MMM, yyyy hh:mm a'),  // "15 Jan, 2024 10:30 AM"
      DateFormat('dd MMM, yyyy'),           // "15 Jan, 2024"
      DateFormat('yyyy-MM-dd HH:mm:ss'),    // SQL datetime
      DateFormat('yyyy-MM-dd'),             // SQL date
    ];
    
    for (var format in formats) {
      try {
        return format.parse(dateString);
      } catch (e) {
        continue;
      }
    }
    
    // Try ISO8601 as last resort
    return DateTime.tryParse(dateString);
  } catch (e) {
    print('Error parsing date: $dateString - $e');
    return null;
  }
}

bool _isEventPast(String dateString) {
  final eventDate = _parseEventDate(dateString);
  if (eventDate == null) return false;
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
  
  return eventDay.isBefore(today);
}

bool _isEventUpcoming(String dateString) {
  final eventDate = _parseEventDate(dateString);
  if (eventDate == null) return true;
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
  
  return eventDay.isAfter(today) || eventDay.isAtSameMomentAs(today);
}

bool _isEventWithin24Hours(String dateString) {
  final eventDate = _parseEventDate(dateString);
  if (eventDate == null) return false;
  
  final now = DateTime.now();
  final difference = eventDate.difference(now);
  
  return difference.inHours > 0 && difference.inHours <= 24;
}


  // ========== USER METHODS ==========

  Future<bool> checkEmailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<bool> checkUsernameExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<void> updateUserRole(String userId, String role) async {
    final db = await database;
    await db.update(
      'users',
      {'role': role},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<String?> getUserRole(String userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (results.isEmpty) return null;
    return results.first['role'] as String?;
  }

  Future<UserModel?> registerUser({
    required String email,
    required String username,
    required String password,
    String role = 'participant',
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
      'role': role,
      'isEmailVerified': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return UserModel(
      id: userId,
      email: email.toLowerCase(),
      username: username,
      role: role,
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
      whereArgs: [
        usernameOrEmail.toLowerCase(),
        usernameOrEmail.toLowerCase(),
        hashedPassword
      ],
    );

    if (results.isEmpty) {
      throw Exception('Invalid username/email or password');
    }

    final userData = results.first;

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
      role: userData['role'] as String? ?? 'participant',
      selectedCategories: (userData['selectedCategories'] as String?)
              ?.split(',')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
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
      role: userData['role'] as String? ?? 'participant',
      selectedCategories: (userData['selectedCategories'] as String?)
              ?.split(',')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
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

  Future<void> deleteProfilePhoto(String userId) async {
    final db = await database;

    await db.update(
      'users',
      {'profilePhotoUrl': null},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<UserModel> updateCategories(
      String userId, List<String> categories) async {
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
      role: userData['role'] as String? ?? 'participant',
      selectedCategories: (userData['selectedCategories'] as String?)
              ?.split(',')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
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

  // ========== EVENT METHODS ==========

  Future<void> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String reason,
  }) async {
    final db = await database;
    
    await db.insert('event_registrations', {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'reason': reason,
      'registeredAt': DateTime.now().toIso8601String(),
      'status': 'registered',
    });
    
    await joinEvent(eventId, userId);
  }

 Future<List<Map<String, dynamic>>> getEventRegistrations(String eventId) async {
  final db = await database;
  
  final registrations = await db.rawQuery('''
    SELECT 
      er.*,
      u.email as userEmail,
      u.username as userName
    FROM event_registrations er
    INNER JOIN users u ON er.userId = u.id
    WHERE er.eventId = ?
    ORDER BY er.registeredAt DESC
  ''', [eventId]);
  
  return registrations;
}



  Future<void> deleteEvent(String eventId) async {
    final db = await database;
    
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
    await db.delete('event_participants', where: 'eventId = ?', whereArgs: [eventId]);
    await db.delete('event_registrations', where: 'eventId = ?', whereArgs: [eventId]);
    await db.delete('favorites', where: 'eventId = ?', whereArgs: [eventId]);
  }

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

  Future<void> joinEvent(String eventId, String userId) async {
    final db = await database;

    final existing = await db.query(
      'event_participants',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );

    if (existing.isNotEmpty) {
      return;
    }

    await db.insert('event_participants', {
      'eventId': eventId,
      'userId': userId,
      'joinedAt': DateTime.now().toIso8601String(),
    });

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

// Get upcoming events that participant has JOINED (after current date)
Future<List<Event>> getUserUpcomingEvents(String userId) async {
  final db = await database;
  
  final registrations = await db.query(
    'event_registrations',
    where: 'user_id = ?',
    whereArgs: [userId],
  );
  
  if (registrations.isEmpty) return [];
  
  final eventIds = registrations.map((r) => r['event_id'] as String).toList();
  final placeholders = eventIds.map((_) => '?').join(',');
  
  final events = await db.query(
    'events',
    where: 'id IN ($placeholders)',
    whereArgs: eventIds,
  );
  
  final allEvents = events.map((map) => Event.fromJson(map)).toList();
  return allEvents.where((event) => _isEventUpcoming(event.date)).toList();
}

// ✅ FIXED: Get past events for PARTICIPANTS (events they JOINED)
Future<List<Event>> getUserPastEvents(String userId) async {
  final db = await database;
  
  final registrations = await db.query(
    'event_registrations',
    where: 'user_id = ?',
    whereArgs: [userId],
  );
  
  if (registrations.isEmpty) return [];
  
  final eventIds = registrations.map((r) => r['event_id'] as String).toList();
  final placeholders = eventIds.map((_) => '?').join(',');
  
  final events = await db.query(
    'events',
    where: 'id IN ($placeholders)',
    whereArgs: eventIds,
  );
  
  final allEvents = events.map((map) => Event.fromJson(map)).toList();
  return allEvents.where((event) => _isEventPast(event.date)).toList();
}

  Future<List<Event>> getPopularEvents({int limit = 4}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'attendeesCount DESC, createdAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  Future<List<Event>> getAllPopularEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'attendeesCount DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) => Event.fromJson(maps[i]));
  }

  Future<List<Event>> getUpcomingEventsByPreferences(List<String> categories,
      {int limit = 4}) async {
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

  Future<List<Event>> getAllUpcomingEventsByPreferences(
      List<String> categories) async {
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

  Future<List<Event>> getRecommendedEvents(List<String> categories,
      {int limit = 4}) async {
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

  Future<bool> isEventFavorited(String eventId, String userId) async {
    final db = await database;
    final results = await db.query(
      'favorites',
      where: 'eventId = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );
    return results.isNotEmpty;
  }

  // ========== ORGANIZER REQUEST METHODS ==========

  Future<bool> hasOrganizerRequest(String userId) async {
    final db = await database;
    final results = await db.query(
      'organizer_requests',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty;
  }

  Future<String?> getOrganizerStatus(String userId) async {
    final db = await database;
    final results = await db.query(
      'organizer_requests',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    return results.first['status'] as String;
  }

  Future<void> createOrganizerRequest({
    required String userId,
    required String organizationName,
    required String socialMediaLink,
  }) async {
    final db = await database;

    await db.insert('organizer_requests', {
      'userId': userId,
      'organizationName': organizationName,
      'socialMediaLink': socialMediaLink,
      'status': 'pending',
      'requestedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> approveOrganizerRequest(String userId) async {
    final db = await database;

    await db.update(
      'organizer_requests',
      {
        'status': 'approved',
        'approvedAt': DateTime.now().toIso8601String(),
      },
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> isApprovedOrganizer(String userId) async {
    final status = await getOrganizerStatus(userId);
    return status == 'approved';
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }


Future<List<Event>> getOrganizerUpcomingEvents(String userId) async {
  final db = await database;
  
  final events = await db.query(
    'events',
    where: 'createdBy = ?',
    whereArgs: [userId],
  );
  
  final allEvents = events.map((map) => Event.fromJson(map)).toList();
  return allEvents.where((event) => _isEventUpcoming(event.date)).toList();
}

// ✅ FIXED: Get past events for ORGANIZERS (events they CREATED)
Future<List<Event>> getOrganizerPastEvents(String userId) async {
  final db = await database;
  
  final events = await db.query(
    'events',
    where: 'createdBy = ?',
    whereArgs: [userId],
  );
  
  final allEvents = events.map((map) => Event.fromJson(map)).toList();
  return allEvents.where((event) => _isEventPast(event.date)).toList();
}

// ========== NEW METHODS FOR REGISTRATION STATUS ==========

// ✅ NEW: Update registration status (for approve/reject)
Future<void> updateRegistrationStatus(String eventId, String userId, String status) async {
  final db = await database;
  
  await db.update(
    'event_registrations',
    {'status': status},
    where: 'eventId = ? AND userId = ?',
    whereArgs: [eventId, userId],
  );
}

// ✅ NEW: Get registration status
Future<String?> getRegistrationStatus(String eventId, String userId) async {
  final db = await database;
  
  final results = await db.query(
    'event_registrations',
    columns: ['status'],
    where: 'eventId = ? AND userId = ?',
    whereArgs: [eventId, userId],
  );
  
  if (results.isEmpty) return null;
  return results.first['status'] as String?;
}

Future<List<Map<String, dynamic>>> getEventsNeedingReminders() async {
  final db = await database;
  
  final events = await db.query('events');
  List<Map<String, dynamic>> needsReminder = [];
  
  for (var eventMap in events) {
    final event = Event.fromJson(eventMap);
    if (_isEventWithin24Hours(event.date)) {
      final registrations = await db.query(
        'event_registrations',
        where: 'eventId = ? AND status = ?',
        whereArgs: [event.id, 'approved'],
      );
      
      for (var reg in registrations) {
        final userId = reg['userId'] as String;
        final userMaps = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        
        if (userMaps.isNotEmpty) {
          needsReminder.add({
            'event': event,
            'userEmail': userMaps.first['email'],
            'userName': userMaps.first['username'],
          });
        }
      }
    }
  }
  
  return needsReminder;
}




Future<UserModel?> getUserByUsername(String username) async {
  final db = await database;
  final results = await db.query(
    'users',
    where: 'LOWER(username) = ?',
    whereArgs: [username.toLowerCase()],
  );
  
  if (results.isEmpty) return null;
  
  final userData = results.first;
  return UserModel(
    id: userData['id'] as String,
    email: userData['email'] as String,
    username: userData['username'] as String,
    profilePhotoUrl: userData['profilePhotoUrl'] as String?,
    role: userData['role'] as String? ?? 'participant',
    selectedCategories: (userData['selectedCategories'] as String?)
            ?.split(',')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [],
  );
}

Future<UserModel?> getUserByEmail(String email) async {
  final db = await database;
  final results = await db.query(
    'users',
    where: 'LOWER(email) = ?',
    whereArgs: [email.toLowerCase()],
  );
  
  if (results.isEmpty) return null;
  
  final userData = results.first;
  return UserModel(
    id: userData['id'] as String,
    email: userData['email'] as String,
    username: userData['username'] as String,
    profilePhotoUrl: userData['profilePhotoUrl'] as String?,
    role: userData['role'] as String? ?? 'participant',
    selectedCategories: (userData['selectedCategories'] as String?)
            ?.split(',')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [],
  );
}}