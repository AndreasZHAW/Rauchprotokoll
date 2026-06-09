import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'smoke_entry.dart';

// Verwaltet die lokale SQLite-Datenbank.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'rauchprotokoll.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            endTimestamp TEXT,
            smellWood INTEGER, smellToxic INTEGER,
            visibleLight INTEGER, visibleStrong INTEGER,
            intensity INTEGER,
            headacheSelf INTEGER, headacheChild INTEGER,
            affectedRooms TEXT, windowState TEXT, measures TEXT,
            note TEXT, photoPath TEXT,
            latitude REAL, longitude REAL,
            temperature REAL, pressure REAL, humidity REAL,
            windSpeed REAL, windDirection REAL, dispersion TEXT
          )
        ''');
      },
    );
  }

  Future<int> insert(SmokeEntry e) async {
    final db = await database;
    final map = e.toMap()..remove('id');
    return db.insert('entries', map);
  }

  Future<List<SmokeEntry>> getAll() async {
    final db = await database;
    final rows = await db.query('entries', orderBy: 'timestamp DESC');
    return rows.map((r) => SmokeEntry.fromMap(r)).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
}
