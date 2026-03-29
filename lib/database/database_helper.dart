import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/chicken.dart';
import '../models/flock_group.dart';
import '../models/loss_event.dart';
import '../models/journal_entry.dart';
import '../models/chick_batch.dart';
import '../models/egg_record.dart';
import '../models/sexing_assessment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chicken_journal.db');
    return openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flock_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chickens (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        breed TEXT,
        hatch_date TEXT,
        color TEXT,
        notes TEXT,
        photo_path TEXT,
        egg_color_category TEXT,
        egg_sample_photos_json TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        flock_group_id TEXT,
        gender TEXT NOT NULL DEFAULT 'unknown',
        acquired_via TEXT NOT NULL DEFAULT 'hatched',
        buy_date TEXT,
        age_at_purchase_weeks INTEGER,
        status TEXT NOT NULL DEFAULT 'active',
        status_date TEXT,
        status_note TEXT,
        purpose TEXT NOT NULL DEFAULT 'layer',
        live_weight_grams REAL,
        dressed_weight_grams REAL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (flock_group_id) REFERENCES flock_groups(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE loss_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        status_applied TEXT NOT NULL,
        date TEXT NOT NULL,
        affected_chicken_ids_json TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        track_type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '',
        photo_paths_json TEXT,
        chick_batch_id TEXT,
        chick_stage TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (chick_batch_id) REFERENCES chick_batches(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE chick_batches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        breed TEXT,
        start_date TEXT NOT NULL,
        egg_count INTEGER NOT NULL,
        eggs_hatched INTEGER,
        incubator_type TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'incubating',
        incubation_days INTEGER NOT NULL DEFAULT 21,
        hatch_window_days INTEGER NOT NULL DEFAULT 3,
        eggs_to_lockdown INTEGER,
        lockdown_dismissed_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE egg_records (
        id TEXT PRIMARY KEY,
        chicken_id TEXT,
        breed_note TEXT,
        weight_grams REAL NOT NULL,
        egg_color_category TEXT NOT NULL,
        date TEXT NOT NULL,
        photo_path TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (chicken_id) REFERENCES chickens(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sexing_assessments (
        id TEXT PRIMARY KEY,
        chicken_id TEXT NOT NULL,
        assessed_at TEXT NOT NULL,
        age_weeks INTEGER,
        claude_result TEXT NOT NULL,
        claude_confidence TEXT NOT NULL,
        claude_reasoning TEXT NOT NULL,
        claude_caveats TEXT,
        user_call TEXT,
        displayed_gender TEXT NOT NULL,
        FOREIGN KEY (chicken_id) REFERENCES chickens(id)
      )
    ''');

    // Indexes for common queries
    await db.execute(
        'CREATE INDEX idx_journal_date ON journal_entries(date DESC)');
    await db.execute(
        'CREATE INDEX idx_journal_track ON journal_entries(track_type)');
    await db.execute('CREATE INDEX idx_eggs_date ON egg_records(date DESC)');
    await db.execute(
        'CREATE INDEX idx_eggs_chicken ON egg_records(chicken_id)');
    await db.execute(
        'CREATE INDEX idx_sexing_chicken ON sexing_assessments(chicken_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS flock_groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color_hex TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute(
          'ALTER TABLE chickens ADD COLUMN flock_group_id TEXT REFERENCES flock_groups(id)');
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE chickens ADD COLUMN gender TEXT NOT NULL DEFAULT 'unknown'");
      await db.execute(
          "ALTER TABLE chickens ADD COLUMN acquired_via TEXT NOT NULL DEFAULT 'hatched'");
      await db.execute(
          'ALTER TABLE chickens ADD COLUMN buy_date TEXT');
      await db.execute(
          'ALTER TABLE chickens ADD COLUMN age_at_purchase_weeks INTEGER');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sexing_assessments (
          id TEXT PRIMARY KEY,
          chicken_id TEXT NOT NULL,
          assessed_at TEXT NOT NULL,
          age_weeks INTEGER,
          claude_result TEXT NOT NULL,
          claude_confidence TEXT NOT NULL,
          claude_reasoning TEXT NOT NULL,
          claude_caveats TEXT,
          user_call TEXT,
          displayed_gender TEXT NOT NULL,
          FOREIGN KEY (chicken_id) REFERENCES chickens(id)
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sexing_chicken ON sexing_assessments(chicken_id)');
    }
    if (oldVersion < 4) {
      await db.execute(
          "ALTER TABLE chickens ADD COLUMN status TEXT NOT NULL DEFAULT 'active'");
      await db.execute(
          'ALTER TABLE chickens ADD COLUMN status_date TEXT');
      await db.execute(
          'ALTER TABLE chickens ADD COLUMN status_note TEXT');
      // Carry over existing is_active=0 birds as deceased
      await db.execute(
          "UPDATE chickens SET status = 'deceased' WHERE is_active = 0");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS loss_events (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          status_applied TEXT NOT NULL,
          date TEXT NOT NULL,
          affected_chicken_ids_json TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute(
          'ALTER TABLE chick_batches ADD COLUMN incubation_days INTEGER NOT NULL DEFAULT 21');
      await db.execute(
          'ALTER TABLE chick_batches ADD COLUMN hatch_window_days INTEGER NOT NULL DEFAULT 3');
    }
    if (oldVersion < 7) {
      await db.execute(
          "ALTER TABLE chickens ADD COLUMN purpose TEXT NOT NULL DEFAULT 'layer'");
      await db.execute(
          'ALTER TABLE chickens ADD COLUMN live_weight_grams REAL');
      await db.execute(
          'ALTER TABLE chickens ADD COLUMN dressed_weight_grams REAL');
      await db.execute(
          'ALTER TABLE chick_batches ADD COLUMN eggs_to_lockdown INTEGER');
      await db.execute(
          'ALTER TABLE chick_batches ADD COLUMN lockdown_dismissed_date TEXT');
    }
  }

  // ─────────────────────────────────────────
  // LOSS EVENTS
  // ─────────────────────────────────────────

  Future<void> insertLossEvent(LossEvent event) async {
    final db = await database;
    await db.insert('loss_events', event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteLossEvent(String id) async {
    final db = await database;
    await db.delete('loss_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LossEvent>> getAllLossEvents() async {
    final db = await database;
    final maps =
        await db.query('loss_events', orderBy: 'date DESC');
    return maps.map(LossEvent.fromMap).toList();
  }

  // ─────────────────────────────────────────
  // FLOCK GROUPS
  // ─────────────────────────────────────────

  Future<void> insertFlockGroup(FlockGroup group) async {
    final db = await database;
    await db.insert('flock_groups', group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFlockGroup(FlockGroup group) async {
    final db = await database;
    await db.update('flock_groups', group.toMap(),
        where: 'id = ?', whereArgs: [group.id]);
  }

  Future<void> deleteFlockGroup(String id) async {
    final db = await database;
    // Unlink any chickens that belong to this group
    await db.update('chickens', {'flock_group_id': null},
        where: 'flock_group_id = ?', whereArgs: [id]);
    await db.delete('flock_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FlockGroup>> getAllFlockGroups() async {
    final db = await database;
    final maps =
        await db.query('flock_groups', orderBy: 'name ASC');
    return maps.map(FlockGroup.fromMap).toList();
  }

  // ─────────────────────────────────────────
  // CHICKENS
  // ─────────────────────────────────────────

  Future<String> insertChicken(Chicken chicken) async {
    final db = await database;
    await db.insert('chickens', chicken.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return chicken.id;
  }

  Future<void> updateChicken(Chicken chicken) async {
    final db = await database;
    await db.update(
      'chickens',
      chicken.toMap(),
      where: 'id = ?',
      whereArgs: [chicken.id],
    );
  }

  Future<void> deleteChicken(String id) async {
    final db = await database;
    await db.delete('egg_records', where: 'chicken_id = ?', whereArgs: [id]);
    await db.delete('sexing_assessments',
        where: 'chicken_id = ?', whereArgs: [id]);
    await db.delete('chickens', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteChickensInGroup(String groupId) async {
    final db = await database;
    // Get IDs first so we can delete their egg records and sexing assessments
    final rows = await db.query('chickens',
        columns: ['id'], where: 'flock_group_id = ?', whereArgs: [groupId]);
    for (final row in rows) {
      final id = row['id'] as String;
      await db.delete('egg_records', where: 'chicken_id = ?', whereArgs: [id]);
      await db.delete('sexing_assessments',
          where: 'chicken_id = ?', whereArgs: [id]);
    }
    await db.delete('chickens',
        where: 'flock_group_id = ?', whereArgs: [groupId]);
  }

  Future<List<Chicken>> getAllChickens({bool activeOnly = false}) async {
    final db = await database;
    final where = activeOnly ? 'is_active = 1' : null;
    final maps = await db.query(
      'chickens',
      where: where,
      orderBy: 'name ASC',
    );
    return maps.map(Chicken.fromMap).toList();
  }

  Future<Chicken?> getChicken(String id) async {
    final db = await database;
    final maps =
        await db.query('chickens', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Chicken.fromMap(maps.first);
  }

  // ─────────────────────────────────────────
  // JOURNAL ENTRIES
  // ─────────────────────────────────────────

  Future<String> insertJournalEntry(JournalEntry entry) async {
    final db = await database;
    await db.insert('journal_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return entry.id;
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {
    final db = await database;
    await db.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JournalEntry>> getJournalEntries({
    String? trackType,
    String? chickBatchId,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (trackType != null && chickBatchId != null) {
      where = 'track_type = ? AND chick_batch_id = ?';
      whereArgs = [trackType, chickBatchId];
    } else if (trackType != null) {
      where = 'track_type = ?';
      whereArgs = [trackType];
    } else if (chickBatchId != null) {
      where = 'chick_batch_id = ?';
      whereArgs = [chickBatchId];
    }

    final maps = await db.query(
      'journal_entries',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map(JournalEntry.fromMap).toList();
  }

  Future<JournalEntry?> getJournalEntry(String id) async {
    final db = await database;
    final maps = await db
        .query('journal_entries', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  // ─────────────────────────────────────────
  // CHICK BATCHES
  // ─────────────────────────────────────────

  Future<String> insertChickBatch(ChickBatch batch) async {
    final db = await database;
    await db.insert('chick_batches', batch.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return batch.id;
  }

  Future<void> updateChickBatch(ChickBatch batch) async {
    final db = await database;
    await db.update(
      'chick_batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<void> deleteChickBatch(String id) async {
    final db = await database;
    await db.delete('chick_batches', where: 'id = ?', whereArgs: [id]);
    // Also clear the batch reference from entries
    await db.update(
      'journal_entries',
      {'chick_batch_id': null, 'chick_stage': null},
      where: 'chick_batch_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ChickBatch>> getAllChickBatches() async {
    final db = await database;
    final maps = await db.query(
      'chick_batches',
      orderBy: 'start_date DESC',
    );
    return maps.map(ChickBatch.fromMap).toList();
  }

  Future<ChickBatch?> getChickBatch(String id) async {
    final db = await database;
    final maps =
        await db.query('chick_batches', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ChickBatch.fromMap(maps.first);
  }

  // ─────────────────────────────────────────
  // EGG RECORDS
  // ─────────────────────────────────────────

  Future<String> insertEggRecord(EggRecord record) async {
    final db = await database;
    await db.insert('egg_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<void> updateEggRecord(EggRecord record) async {
    final db = await database;
    await db.update(
      'egg_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteEggRecord(String id) async {
    final db = await database;
    await db.delete('egg_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EggRecord>> getAllEggRecords({String? chickenId}) async {
    final db = await database;
    final maps = await db.query(
      'egg_records',
      where: chickenId != null ? 'chicken_id = ?' : null,
      whereArgs: chickenId != null ? [chickenId] : null,
      orderBy: 'date DESC',
    );
    return maps.map(EggRecord.fromMap).toList();
  }

  /// Returns egg records within a date range (inclusive).
  Future<List<EggRecord>> getEggRecordsInRange(
      DateTime from, DateTime to) async {
    final db = await database;
    final maps = await db.query(
      'egg_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        from.toIso8601String(),
        to.add(const Duration(days: 1)).toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return maps.map(EggRecord.fromMap).toList();
  }

  /// Returns total egg count per chicken for the last N days.
  Future<Map<String, int>> getEggsPerChickenLastDays(int days) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final result = await db.rawQuery('''
      SELECT chicken_id, COUNT(*) as count
      FROM egg_records
      WHERE date >= ?
      GROUP BY chicken_id
    ''', [since]);

    return {
      for (final row in result)
        (row['chicken_id'] as String? ?? 'unknown'):
            (row['count'] as int)
    };
  }

  /// Returns all egg records for insights calculations.
  Future<Map<String, dynamic>> getEggStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        AVG(weight_grams) as avg_weight,
        MIN(weight_grams) as min_weight,
        MAX(weight_grams) as max_weight
      FROM egg_records
    ''');
    return result.first;
  }

  /// Returns egg count grouped by month (YYYY-MM).
  Future<List<Map<String, dynamic>>> getEggsByMonth() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        strftime('%Y-%m', date) as month,
        COUNT(*) as count,
        chicken_id
      FROM egg_records
      GROUP BY month, chicken_id
      ORDER BY month ASC
    ''');
  }

  // ─────────────────────────────────────────
  // SEXING ASSESSMENTS
  // ─────────────────────────────────────────

  Future<void> insertSexingAssessment(SexingAssessment assessment) async {
    final db = await database;
    await db.insert('sexing_assessments', assessment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSexingAssessment(String id) async {
    final db = await database;
    await db.delete('sexing_assessments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SexingAssessment>> getAssessmentsForChicken(
      String chickenId) async {
    final db = await database;
    final maps = await db.query(
      'sexing_assessments',
      where: 'chicken_id = ?',
      whereArgs: [chickenId],
      orderBy: 'assessed_at DESC',
    );
    return maps.map(SexingAssessment.fromMap).toList();
  }

  /// Returns per-chicken egg count for the Flock tab badge.
  Future<int> getEggsThisWeek(String chickenId) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_records
      WHERE chicken_id = ? AND date >= ?
    ''', [chickenId, since]);
    return (result.first['count'] as int);
  }
}
