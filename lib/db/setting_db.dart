import 'package:BackArt/model/setting.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'db_base.dart';

class SettingDb extends DbBase {
  static SettingDb? _instance;
  static SettingDb instance() {
    if (_instance == null) {
      // _instance = SettingDb();
    }
    return _instance ??= SettingDb();
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
    var settingJson = setting?.toJson();
    if (settingJson != null) {
      await update({
        SettingModel.idField: setting?.id,
      }, map);
    } else {
      await insert(map);
    }
  }
}
