import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchUri(String url) async {
  try{
    await launchUrl(Uri.parse(url));
  }catch(e){
    Fluttertoast.showToast(msg: "打开连接异常");
    print("e====>${e}");
  }
}