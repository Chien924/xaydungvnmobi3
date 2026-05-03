import 'package:flutter/material.dart';

import 'screens/app_start_page.dart';

void main() {
  runApp(const XayDungVnApp());
}

class XayDungVnApp extends StatelessWidget {
  const XayDungVnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xây Dựng VN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff16a34a)),
        scaffoldBackgroundColor: const Color(0xfff4f7fb),
        fontFamily: 'Arial',
      ),
      home: const AppStartPage(),
    );
  }
}
