import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class UploadQueueDB {
  static const String _tableName = 'consultation_upload_queue';
  static const String _dbName = 'upload_queue.db';

  // No static _database anymore — we open fresh every time

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hive_key INTEGER NOT NULL,
            file_path TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertPending({
    required int hiveKey,
    required String filePath,
  }) async {
    final db = await _open();
    try {
      await db.insert(
        _tableName,
        {
          'hive_key': hiveKey,
          'file_path': filePath,
          'status': 'pending',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } finally {
      await db.close(); // always close after use in non-main isolate
    }
  }

  Future<Map<String, dynamic>?> getNextPending() async {
    final db = await _open();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: "status = ?",
        whereArgs: ['pending'],
        orderBy: "created_at ASC",
        limit: 1,
      );
      return maps.isNotEmpty ? maps.first : null;
    } finally {
      await db.close();
    }
  }

  Future<void> markAsUploading(int id) async {
    final db = await _open();
    try {
      await db.update(
        _tableName,
        {'status': 'uploading'},
        where: 'id = ?',
        whereArgs: [id],
      );
    } finally {
      await db.close();
    }
  }

  Future<void> markAsDone(int id) async {
    final db = await _open();
    try {
      await db.update(
        _tableName,
        {'status': 'done'},
        where: 'id = ?',
        whereArgs: [id],
      );
    } finally {
      await db.close();
    }
  }

  Future<void> deleteRow(int id) async {
    final db = await _open();
    try {
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } finally {
      await db.close();
    }
  }

  Future<void> resetUploadingToPending() async {
    final db = await _open();
    try {
      await db.update(
        _tableName,
        {'status': 'pending'},
        where: 'status = ?',
        whereArgs: ['uploading'],
      );
    } finally {
      await db.close();
    }
  }

  Future<int> getPendingCount() async {
    final db = await _open();
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          "SELECT COUNT(*) FROM $_tableName WHERE status IN ('pending', 'uploading')",
        ),
      );
      return count ?? 0;
    } finally {
      await db.close();
    }
  }

  Future<bool> hasPending() async {
    final db = await _open();
    try {
      final result = await db.rawQuery(
        "SELECT 1 FROM $_tableName WHERE status IN ('pending', 'uploading') LIMIT 1",
      );
      return result.isNotEmpty;
    } finally {
      await db.close();
    }
  }
}