import 'dart:async';
import 'package:BackArt/model/setting.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'db_base.dart';

class SettingDb extends DbBase {
  static SettingDb? _instance;
  static Completer<SettingDb>? _completer;

  // 私有构造函数
  SettingDb._();

  // 异步获取实例的方法
  static Future<SettingDb> instance() async {
    if (_instance != null) {
      return _instance!;
    }

    // 使用 Completer 防止多次初始化
    if (_completer == null) {
      _completer = Completer<SettingDb>();
      try {
        final settingDb = SettingDb._();
        await settingDb.init(); // 调用 DbBase 中的 init
        _instance = settingDb;
        _completer!.complete(_instance);
      } catch (e) {
        _completer!.completeError(e);
      }
    }
    return _completer!.future;
  }

  @override
  String tableName = "settings";

  @override
  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ${SettingModel.languageField} TEXT UNIQUE
      )
    ''');
  }

  Future<SettingModel?> getSettings() async {
    List<Map<String, Object?>> settingList = await find();
    if (settingList.isNotEmpty) {
      return SettingModel.fromJson(settingList.first);
    }
    return null;
  }

  Future<void> updateOrInsert(Map<String, dynamic> map) async {
    SettingModel? setting = await getSettings();
    if (setting != null) {
      await update({SettingModel.idField: setting.id}, map);
    } else {
      await insert(map);
    }
  }
}