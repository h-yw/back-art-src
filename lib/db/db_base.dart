import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

abstract class DbBase {
  static const String _dbName = "back_art";
  static const int _newVersion = 1;

  static late final Database _database;

  abstract String tableName;

  bool exists = false;

  @protected
  Database get db => _database;

  onReload(Database db, int version) {}

  Future<void> onCreate(Database db, int version);

  onUpgrade(Database db, int oldVersion, int newVersion) {}

  onDowngrade(Database db, int oldVersion, int newVersion) {}

  DbBase();

  static bool _isDatabaseInitialized() {
    try {
      _database;
      return true;
    } catch (_) {
      return false;
    }
  }

  @protected
  Future<void> init() async {
    if (_isDatabaseInitialized()) {
      return;
    }

    var databasePath = await getDatabasesPath();
    var dbBasePath = "$databasePath/$_dbName.db";
    int oldVersion = 0;

    _database = await openDatabase(
      dbBasePath,
      version: _newVersion,
      onUpgrade: (db, old, newV) {
        oldVersion = old;
      },
      onDowngrade: (db, old, newV) {
        oldVersion = old;
      },
    );

    onReload(_database, _newVersion);
    exists = await tableExists();
    if (!exists) {
      await onCreate(_database, _newVersion);
      exists = true;
    }

    if (oldVersion != 0) {
      if (oldVersion > _newVersion) {
        await onDowngrade(_database, oldVersion, _newVersion);
      } else if (oldVersion < _newVersion) {
        await onUpgrade(_database, oldVersion, _newVersion);
      }
    }
  }

  Future<bool> tableExists() async {
    var res = await _database.rawQuery(
      "SELECT * FROM sqlite_master WHERE TYPE = 'table' AND NAME = '$tableName'",
    );
    return res.isNotEmpty;
  }

  Future<bool> columnExists(String columnName) async {
    var result = await _database.rawQuery('PRAGMA table_info($tableName)');
    return result.any((row) => row['name'] == columnName);
  }

  Future addColumn(String columnName, String type) async {
    return await _database.rawQuery("ALTER TABLE $tableName ADD $columnName $type");
  }

  dropTable() async {
    await _database.execute("drop table if exists $tableName;");
  }

  insert(Map<String, Object?> values) async {
    return _database.insert(tableName, values);
  }

  remove(Map<String, Object?> json) async {
    if (json.isEmpty) return 0;
    String whereClause = json.keys.map((key) => '$key = ?').join(' AND ');
    List<Object?> whereArgs = json.values.toList();
    return _database.delete(tableName, where: whereClause, whereArgs: whereArgs);
  }

  update(Map<String, Object?> whereJson, Map<String, Object?> dataJson) async {
    if (whereJson.isEmpty) return 0;
    String whereClause = whereJson.keys.map((key) => '$key = ?').join(' AND ');
    List<Object?> whereArgs = whereJson.values.toList();
    return _database.update(tableName, dataJson, where: whereClause, whereArgs: whereArgs);
  }

  Future<List<Map<String, Object?>>> find({
    Map<String, dynamic>? where,
    int? page,
    int? pageSize,
  }) async {
    String? whereClause;
    List<Object?>? whereArgs;

    if (where != null && where.isNotEmpty) {
      whereClause = where.keys.map((key) => '$key = ?').join(' AND ');
      whereArgs = where.values.toList();
    }

    var result = await _database.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      offset: page == null ? null : (page - 1) * (pageSize ?? 1),
      limit: pageSize,
    );
    return result;
  }

  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return _database.rawQuery(sql, arguments);
  }
}