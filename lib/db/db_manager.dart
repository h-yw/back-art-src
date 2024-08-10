import 'package:BackArt/db/setting_db.dart';

class DbManager{
  static forFeature() async{
    List<SettingDb> list =[
      SettingDb.instance(),
    ];
    for(int i = 0; i < list.length; i++){
      var entity = list[i];
      while(!entity.exists){
        await Future.delayed(const Duration(microseconds: 60),(){});
      }
    }
  }
}