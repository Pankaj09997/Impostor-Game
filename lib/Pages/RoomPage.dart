import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/CodePage.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with SingleTickerProviderStateMixin {
  String? joiningCode = "ABC123";
  List<String>? joinedPlayers = ["Alice", "Bob", "Charlie"];
  late Animation<double> buttonAnimation;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(animationController);
    _startAnimation();
  }

  void _startAnimation() async {
    animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(50, 0, 0, 0),
          child: Text(
            "The Chamber",
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 24),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          // Game code card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    "ROOM CODE",
                    style: GoogleFonts.fredoka(
                      color: Colors.white60,
                      fontSize: 13,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    joiningCode ?? "------",
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontSize: 36,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  "PLAYERS",
                  style: GoogleFonts.fredoka(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${joinedPlayers?.length ?? 0}",
                    style: GoogleFonts.fredoka(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: joinedPlayers?.length ?? 0,
              itemBuilder: (context, index) {
                final singleElement = joinedPlayers?[index] ?? "";
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.yellow.shade700,
                          child: Text(
                            singleElement[0].toUpperCase(),
                            style: GoogleFonts.fredoka(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          singleElement,
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.circle,
                          color: Colors.greenAccent,
                          size: 10,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          AnimatedBuilder(
            animation: buttonAnimation,
            builder: (context, child) {
              final scale = 1 + (buttonAnimation.value * 0.05);
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, _, _) => CodePage(),
                    transitionsBuilder: (_, animation, _, child) {
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
        ],
      ),
    );
  }
}
