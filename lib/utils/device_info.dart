import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future getDeviceInfo()async{
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if(Platform.isAndroid){
    return await deviceInfo.androidInfo;
  }else if(Platform.isIOS){
    return await deviceInfo.iosInfo;
  }else{
    return null;
  }
}