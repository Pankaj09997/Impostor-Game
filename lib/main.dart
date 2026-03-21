import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:impostorgame/Pages/SplashScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SplashScreen());
  }
}
