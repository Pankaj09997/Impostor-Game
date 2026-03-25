import 'package:flutter/material.dart';
import 'package:impostorgame/Pages/HomePage.dart';
import 'package:impostorgame/Pages/SplashScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(NextScreen: Homepage()),
    );
  }
}
