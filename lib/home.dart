import 'package:BackArt/pages/created/created.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() {
    return _Home();
  }
}

class _Home extends State<Home> {
  int currentIndex = 0;
  final pages = [
    const Created(),
  ];
  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    // 设置沉浸式界面
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarColor: Colors.transparent,
    //   systemNavigationBarColor: Colors.transparent,
    //   systemNavigationBarIconBrightness: Brightness.light,
    //   statusBarIconBrightness: Brightness.light,
    // ));

    // 隐藏系统状态栏和导航栏
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          // bottomNavigationBar: BottomNavigationBar(
          //   elevation: 2,
          //   items: const [
          //     BottomNavigationBarItem(
          //         icon: Icon(Icons.directions_car), label: "create"),
          //     BottomNavigationBarItem(
          //         icon: Icon(Icons.directions_transit), label: "about")
          //   ],
          //   type: BottomNavigationBarType.fixed,
          //   currentIndex: currentIndex,
          //   onTap:_changePage,
          // ),
          body: SafeArea(
            child: pages[currentIndex],
          ),
        ));
  }
}
