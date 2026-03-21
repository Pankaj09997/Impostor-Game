import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late Animation<Offset> headerAnimation;
  late Animation<Offset> subtitleAnimation;
  late AnimationController headerAnimationController;
  late AnimationController subtitleAnimationController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar());
  }
}
