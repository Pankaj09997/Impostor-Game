import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/GameCountDown.dart';
import 'package:impostorgame/Words/words.dart';

class RoomPage extends StatefulWidget {
  final String? roomId;
  final bool? isAdmin;
  final String? playerName;
  const RoomPage({super.key, this.roomId, this.isAdmin, this.playerName});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> joinedPlayers = [];
  late Animation<double> buttonAnimation;
  late AnimationController animationController;
  StreamSubscription? _roomSubscription;
  late final AppLifecycleListener appLifecycleListener;
  String? getHostName;
  bool hasStartButtonClicked = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    HostName();
    gethostName();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(animationController);
    animationController.repeat(reverse: true);
    _listenToPlayers();

    appLifecycleListener = AppLifecycleListener(
      onDetach: () async {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({
              'players': FieldValue.arrayRemove([widget.playerName]),
            });

        final data = await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .get();

        if (!data.exists) return;

        final currentHost = data['hostName'];
        final List<dynamic> remainingPlayers = data['players'] ?? [];

        if (widget.playerName == currentHost) {
          await changeHost(remainingPlayers);
        }
      },
    );
  }

  void _listenToPlayers() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            setState(() {
              joinedPlayers = snapshot['players'] ?? [];
              getHostName = snapshot['hostName'];
            });

            final status = snapshot['status'];

            if (status == 'ready' && !_hasNavigated) {
              _hasNavigated = true;
              _roomSubscription?.cancel();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, _, __) => GameCountDown(
                    playerName: widget.playerName!,
                    roomId: widget.roomId!,
                  ),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            }
          }
        });
  }

  Future<void> gethostName() async {
    final data = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    setState(() {
      getHostName = data['hostName'];
    });
  }

  Future<void> HostName() async {
    if (widget.isAdmin == true) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({'hostName': widget.playerName}, SetOptions(merge: true));
    }
  }

  Future<void> _removePlayerAndLeave() async {
    if (widget.roomId != null && widget.playerName != null) {
      final roomRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId);

      final doc = await roomRef.get();
      final hostName = doc['hostName'];
      List players = List.from(doc['players']);

      players.remove(widget.playerName);

      if (widget.playerName == hostName) {
        if (players.isNotEmpty) {
          await roomRef.update({'hostName': players.first, 'players': players});
        } else {
          await roomRef.delete();
        }
      } else {
        await roomRef.update({'players': players});
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> changeHost(List<dynamic> remainingPlayers) async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId);

    if (remainingPlayers.isNotEmpty) {
      await roomRef.update({'hostName': remainingPlayers.first});
    } else {
      await roomRef.delete();
    }
  }

  Future<void> startGame() async {
    if (joinedPlayers.length < 4) return;
    _hasNavigated = false;
    final random = Random();
    final impostorName = joinedPlayers[random.nextInt(joinedPlayers.length)];

    final categories = words.keys.toList();

    final category = categories[random.nextInt(categories.length)];

    final wordList = words[category]!;

    final wordPair = wordList[random.nextInt(wordList.length)];
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .update({
          'impostorName': impostorName,
          'crewmateWord': wordPair['crewmate'],
          'crewmateWordMeaning': wordPair['crewmateMeaning'],
          'impostorWord': wordPair['impostor'],
          'impostorWordMeaning': wordPair['impostorMeaning'],
          'category': category,
          'votes': {},
          'result': null,
          'accused': null,
          'status': 'ready',
        });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    appLifecycleListener.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _removePlayerAndLeave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Stack(
          children: [
            // ── Atmospheric glow top-left ──
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE53935).withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Atmospheric glow bottom-right ──
            Positioned(
              bottom: 40,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE53935).withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Grid ──
            CustomPaint(
              size: Size(size.width, size.height),
              painter: _GridPainter(),
            ),

            // ── Main content ──
            SafeArea(
              child: Column(
                children: [
                  // ── Custom AppBar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _removePlayerAndLeave,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "THE CHAMBER",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        // Live indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.greenAccent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "LIVE",
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Room Code Card ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE53935).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "ROOM CODE",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white30,
                              fontSize: 11,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.roomId ?? "------",
                            style: GoogleFonts.bebasNeue(
                              color: Colors.white,
                              fontSize: 42,
                              letterSpacing: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Players header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          "PLAYERS",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white30,
                            fontSize: 11,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE53935).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            "${joinedPlayers.length}",
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFFE53935),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Players list ──
                  Expanded(
                    child: joinedPlayers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.hourglass_empty_rounded,
                                  color: Colors.white12,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Waiting for players...",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white24,
                                    fontSize: 15,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: joinedPlayers.length,
                            itemBuilder: (context, index) {
                              final player = joinedPlayers[index];
                              final bool isHost = player == getHostName;
                              final bool isMe = player == widget.playerName;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHost
                                        ? const Color(
                                            0xFFE53935,
                                          ).withOpacity(0.08)
                                        : Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isHost
                                          ? const Color(
                                              0xFFE53935,
                                            ).withOpacity(0.35)
                                          : Colors.white12,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar circle
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isHost
                                              ? const Color(0xFFE53935)
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            player[0].toUpperCase(),
                                            style: GoogleFonts.bebasNeue(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Name + label
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (isHost)
                                            Text(
                                              "HOST",
                                              style: GoogleFonts.spaceGrotesk(
                                                color: const Color(0xFFE53935),
                                                fontSize: 10,
                                                letterSpacing: 2,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          else if (isMe)
                                            Text(
                                              "YOU",
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white30,
                                                fontSize: 10,
                                                letterSpacing: 2,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),

                                      const Spacer(),

                                      // Status icon
                                      if (isHost)
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFE53935),
                                          size: 18,
                                        )
                                      else
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),

                  // ── Start Game button — host only ──
                  if (getHostName == widget.playerName)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: AnimatedBuilder(
                        animation: buttonAnimation,
                        builder: (context, child) {
                          final scale = 1 + (buttonAnimation.value * 0.03);
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (joinedPlayers.length <= 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Need at least 4 players to start 👀",
                                    style: GoogleFonts.spaceGrotesk(),
                                  ),
                                  backgroundColor: const Color(0xFFE53935),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } else {
                              startGame();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE53935,
                                  ).withOpacity(0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "START GAME",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid background painter ───────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
