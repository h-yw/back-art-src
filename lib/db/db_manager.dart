import 'package:BackArt/db/setting_db.dart';

class DbManager {
  static Future<void> initialize() async {
    // 调用异步单例，它会返回一个完全初始化好的实例
    await SettingDb.instance();
  }
}