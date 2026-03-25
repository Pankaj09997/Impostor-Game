import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/GameFinalPageSplash.dart';

class GameCountDown extends StatefulWidget {
  const GameCountDown({super.key});

  @override
  State<GameCountDown> createState() => _GameCountDownState();
}

class _GameCountDownState extends State<GameCountDown>
    with TickerProviderStateMixin {
  int count = 3;
  @override
  void initState() {
    startCountdown();
    super.initState();
  }

  void startCountdown() async {
    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        count--;
      });
      if (count > 0) {
        startCountdown();
      } else {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, _, _) => GameFinalSplashScreen(),
            transitionDuration: Duration.zero,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              animation:
              animation;
              return ScaleTransition(scale: animation, child: child);
            },
            child: Center(
              child: Text(
                count > 0 ? "$count" : "GO!",
                key: ValueKey(count),
                style: GoogleFonts.bebasNeue(
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
