import 'package:sqflite/sqflite.dart';

abstract class DbBase {
  static const String _dbName = "back_art";
  static const int _newVersion = 1;
  static int _oldVersion = 0;
  static String? _dbBasePath;

  static Database? _database;

  ///表名称
  abstract String tableName;

  ///表是否存在
  bool exists = false;

  ///数据库实例化完成
  onReload(Database db, int version) {}

  ///创建表
  Future<void> onCreate(Database db, int version);

  ///更新表
  onUpgrade(Database db, int oldVersion, int newVersion) {}

  ///数据库降级
  onDowngrade(Database db, int oldVersion, int newVersion) {}

  DbBase() {
    _initDatabase();
  }
  Future<Database> _initDatabase() async {
    var databasePath = await getDatabasesPath();
    _dbBasePath ??= "$databasePath/$_dbName.db";
    _database ??= await openDatabase(
      _dbBasePath!,
      version: _newVersion,
      // onConfigure: (db) { },
      // onCreate: onCreate,
      onUpgrade: (db, old, newV) {
        _oldVersion = old;
      },
      onDowngrade: (db, old, newV) {
        _oldVersion = old;
      },
      // onOpen: onOpen,
    );
    onReload(_database!, _newVersion);
    //判断表是否存在
    exists = await tableExists();
    if (!exists) {
      await onCreate(_database!, _newVersion);
      exists = true;
    }

    if (_oldVersion != 0) {
      if (_oldVersion > _newVersion) {
        //数据库降级了
        await onDowngrade(
          _database!,
          await _database!.getVersion(),
          _newVersion,
        );
      } else if (_oldVersion < _newVersion) {
        //数据库升级了
        await onUpgrade(
          _database!,
          _oldVersion, //await _database!.getVersion(),
          _newVersion,
        );
      }
    }

    return _database!;
  }

  ///表是否存在
  Future<bool> tableExists() async {
    //内建表sqlite_master
    var res = await _database!.rawQuery(
      "SELECT * FROM sqlite_master WHERE TYPE = 'table' AND NAME = '$tableName'",
    );
    return res.isNotEmpty;
  }

  ///表列是否存在
  Future<bool> columnExists(String columnName) async {
    var result = await _database!.rawQuery("""
      SELECT sql FROM sqlite_master WHERE type='table' AND name='$tableName' COLLATE NOCASE limit 1
    """);
    String sql = result[0]["sql"] as String;
    int startIndex = sql.indexOf("(") + 1;
    int endIndex = sql.indexOf(")");
    sql = sql.substring(startIndex, endIndex);

    List<String> sqlList = sql.split(",").map((e) => e.trim()).toList();
    bool exists = false;
    for (int j = 0; j < sqlList.length; j++) {
      var rowStr = sqlList[j].trim().split(",").join("");
      var colName = rowStr.split(" ")[0].trim();
      if (colName == columnName) {
        exists = true;
        break;
      }
    }
    return exists;
  }

  ///新增列
  Future addColumn(String columnName, String type) async {
    return await _database!.rawQuery("""
      ALTER TABLE $tableName ADD  $columnName $type
    """);
  }

  ///删表
  dropTable() async {
    if (_database == null) {
      await _initDatabase();
    }
    await _database!.execute("""
      drop table if exists $tableName;
    """);
  }

  Database get database => _database!;

  ///插入数据
  insert(Map<String, Object?> values) async {
    return database.insert(tableName, values);
  }

  ///删除数据
  remove(Map<String, Object?> json) async {
    List<String> keys = json.keys.toList();
    List<String> where = [];
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      where.add("$key=${json[key]}");
    }

    return database.delete(
      tableName,
      where: where.join(" and "),
    );
  }

  ///修改数据
  update(Map<String, Object?> json1, Map<String, Object?> json2) async {
    List<String> keys = json1.keys.toList();
    List<String> where = [];
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      if (json1[key].runtimeType == String) {
        where.add("$key='${json1[key]}'");
      } else {
        where.add("$key=${json1[key]}");
      }
    }

    return database.update(
      tableName,
      json2,
      where: where.isEmpty ? null : where.join(" and "),
    );
  }

  ///缓存的数据
  static final Map<String, List<Map<String, Object?>>> _findCache = {};

  ///查找数据
  Future<List<Map<String, Object?>>> find({
    Map<String, dynamic>? where,
    int? page,
    int? pageSize,
  }) async {
    List<String> keys = where?.keys.toList() ?? [];

    List<String> whereList = [];
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      if (where![key].runtimeType == String) {
        whereList.add("$key='${where[key]}'");
      } else {
        whereList.add("$key=${where[key]}");
      }
    }

    String sql = whereList.join(" and ");
    String mapKey = "${tableName}_${sql}_page=${page}_pageSize=$pageSize";

    List data = sql.isEmpty ? [] : (_findCache[mapKey] ?? []);
    if (data.isNotEmpty) {
      return _findCache[mapKey]!;
    }

    var result = await database.query(
      tableName,
      where: sql.isEmpty ? null : sql,
      offset: page == null ? null : (page - 1) * (pageSize ?? 1),
      limit: pageSize,
    );
    if (sql.isNotEmpty) {
      _findCache[mapKey] = result;
    }
    return result;
  }

  Future<List<Map<String, Object?>>> rawQuery(String sql) async {
    return database.rawQuery(sql);
  }
}
