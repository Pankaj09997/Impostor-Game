import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/CodePage.dart';
import 'package:impostorgame/Pages/NamePage.dart';
import 'package:impostorgame/Pages/RoomPage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  late Animation<double> _imageVibration;
  late AnimationController _imageController;
  late Animation<double> _buttonAnimation;
  late AnimationController _buttonController;
  bool _isCreatingRoom = false;
  String createRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<String> saveRoomId() async {
    final roomId = createRoomId();
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'roomId': roomId,
      'players': [],
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return roomId;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
    );
    _imageController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _imageVibration = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeInOut),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_buttonController);
    _startAnimation();
  }

  void _startAnimation() async {
    _imageController.repeat(reverse: true);
    _buttonController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _imageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Center(
          child: Text(
            "The Lobby",
            style: GoogleFonts.fredoka(
              textStyle: TextStyle(color: Colors.white),
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 50),

          AnimatedBuilder(
            animation: _imageVibration,
            builder: (context, child) {
              final angle = (_imageVibration.value - 0.5) * 0.06;
              return Transform.rotate(angle: angle, child: child);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
              child: SvgPicture.asset("assets/SplashImage.svg"),
            ),
          ),
          SizedBox(height: 50),

          AnimatedBuilder(
            animation: _buttonAnimation,
            builder: (context, child) {
              final scale = 1 + (_buttonAnimation.value * 0.05);
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: _isCreatingRoom
                  ? null
                  : () async {
                      setState(() => _isCreatingRoom = true);
                      try {
                        final roomId = await saveRoomId();
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, _, __) =>
                                NamePage(roomId: roomId, isAdmin: true),
                            transitionsBuilder: (_, animation, __, child) {
                              return SlideTransition(
                                position:
                                    Tween(
                                      begin: Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Couldn't create room 😬 Try again",
                              style: GoogleFonts.fredoka(),
                            ),
                            backgroundColor: Colors.yellow.shade700,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isCreatingRoom = false);
                      }
                    },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 50),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  "Start Game",
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _buttonAnimation,
            builder: (context, child) {
              final scale = 1 + (_buttonAnimation.value * 0.05);
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, _, __) => CodePage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween(begin: Offset(1, 0), end: Offset.zero)
                            .animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 50),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  "Join the existing Game",
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
