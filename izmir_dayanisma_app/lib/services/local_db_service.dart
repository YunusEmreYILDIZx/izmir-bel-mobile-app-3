// lib/services/local_db_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class LocalDbService {
  static Database? _database;

  /// Singleton instance
  static Future<LocalDbService> getInstance() async {
    final service = LocalDbService();
    await service._initDb();
    return service;
  }

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'dayanisma.db'),
      version: 7, // v7: added age, gender, district to users
      onCreate: (db, version) async {
        // 1) users table with profile columns
        await db.execute('''
          CREATE TABLE users (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            name     TEXT,
            email    TEXT UNIQUE,
            password TEXT,
            role     TEXT     DEFAULT 'user',
            age      INTEGER  DEFAULT 0,
            gender   TEXT     DEFAULT '',
            district TEXT     DEFAULT ''
          )
        ''');

        // seed admin
        await db.insert('users', {
          'name': 'Admin',
          'email': 'admin@admin.com',
          'password': 'admin123',
          'role': 'admin',
          'age': 0,
          'gender': '',
          'district': '',
        });

        // 2) events table
        await db.execute('''
          CREATE TABLE events (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            title       TEXT,
            description TEXT,
            date        TEXT,
            location    TEXT
          )
        ''');

        // 3) participations table
        await db.execute('''
          CREATE TABLE participations (
            user_email TEXT,
            event_id   INTEGER,
            PRIMARY KEY(user_email, event_id),
            FOREIGN KEY(user_email) REFERENCES users(email),
            FOREIGN KEY(event_id) REFERENCES events(id)
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // v1→v2: create events
          await db.execute('''
            CREATE TABLE events (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              title       TEXT,
              description TEXT,
              date        TEXT,
              location    TEXT
            )
          ''');
        }
        if (oldV < 3) {
          // v2→v3: add role
          await db.execute(
            "ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'",
          );
        }
        if (oldV < 5) {
          // v4→v5: create participations
          await db.execute('''
            CREATE TABLE participations (
              user_email TEXT,
              event_id   INTEGER,
              PRIMARY KEY(user_email, event_id),
              FOREIGN KEY(user_email) REFERENCES users(email),
              FOREIGN KEY(event_id) REFERENCES events(id)
            )
          ''');
        }
        if (oldV < 7) {
          // v6→v7: add profile columns
          await db.execute(
            'ALTER TABLE users ADD COLUMN age INTEGER DEFAULT 0',
          );
          await db.execute(
            "ALTER TABLE users ADD COLUMN gender TEXT DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE users ADD COLUMN district TEXT DEFAULT ''",
          );
        }
      },
    );
  }

  Database get db {
    if (_database == null) throw Exception('Database not initialized!');
    return _database!;
  }

  // --- Event CRUD ---
  Future<int> insertEvent(Event e) => db.insert('events', e.toMap());
  Future<List<Event>> getAllEvents() async {
    final maps = await db.query('events', orderBy: 'date DESC');
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  Future<int> updateEvent(Event e) =>
      db.update('events', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  Future<int> deleteEvent(int id) =>
      db.delete('events', where: 'id = ?', whereArgs: [id]);

  // --- Participation ---
  Future<void> joinEvent(String userEmail, int eventId) async {
    await db.insert('participations', {
      'user_email': userEmail,
      'event_id': eventId,
    });
  }

  Future<bool> isJoined(String userEmail, int eventId) async {
    final rows = await db.query(
      'participations',
      where: 'user_email = ? AND event_id = ?',
      whereArgs: [userEmail, eventId],
    );
    return rows.isNotEmpty;
  }

  Future<List<Event>> getJoinedEvents(String userEmail) async {
    final rows = await db.query(
      'participations',
      columns: ['event_id'],
      where: 'user_email = ?',
      whereArgs: [userEmail],
    );
    if (rows.isEmpty) return [];
    final ids = rows.map((r) => r['event_id'] as int).toList();
    final ph = List.filled(ids.length, '?').join(',');
    final maps = await db.query(
      'events',
      where: 'id IN ($ph)',
      whereArgs: ids,
      orderBy: 'date DESC',
    );
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// For admin: fetch participants’ name & email
  Future<List<Map<String, dynamic>>> getParticipantsForEvent(
    int eventId,
  ) async {
    return await db.rawQuery(
      '''
      SELECT u.name, u.email
        FROM participations p
        JOIN users u ON p.user_email = u.email
       WHERE p.event_id = ?
    ''',
      [eventId],
    );
  }
}
