import 'dart:async';
import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/GameCountDown.dart';

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
  bool? hasHostPlayerLeaved = false;
  bool? hasHostPlayerClosed = false;

  @override
  void initState() {
    super.initState();
    HostName();
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
      onDetach: () {
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({
              'players': FieldValue.arrayRemove([widget.playerName]),
            });
        setState(() {
          hasHostPlayerClosed = true;
        });
      },
    );
  }

  void _listenToPlayers() {
    print("RoomId:${widget.roomId}");
    _roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            setState(() {
              joinedPlayers = snapshot['players'] ?? [];
              print("Players List:$joinedPlayers");
            });
          }
        });
  }

  Future<void> gethostName() async {
    final data = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    final hostName = data['hostName'];
    setState(() {
      getHostName = hostName;
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
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            'players': FieldValue.arrayRemove([widget.playerName]),
          });
      setState(() {
        hasHostPlayerLeaved = true;
      });
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> changeHost() async {
    if (hasHostPlayerClosed == true || hasHostPlayerLeaved == true) {
      String newHost = joinedPlayers.first;
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'hostName': newHost});
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    appLifecycleListener.dispose();
    animationController.dispose();
    Future<void> removePlayerAndLeave() async {
      if (widget.roomId != null && widget.playerName != null) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({
              'players': FieldValue.arrayRemove([widget.playerName]),
            });
      }
      if (mounted) Navigator.pop(context);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _removePlayerAndLeave();
      },
      child: Scaffold(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
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
                      widget.roomId ?? "------",
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
                      "${joinedPlayers.length}",
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
              child: joinedPlayers.isEmpty
                  ? Center(
                      child: Text(
                        "Waiting for players... 👀",
                        style: GoogleFonts.fredoka(
                          color: Colors.white54,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: joinedPlayers.length,
                      itemBuilder: (context, index) {
                        final player = joinedPlayers[index];
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
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.yellow.shade700,
                                  child: Text(
                                    player[0].toUpperCase(),
                                    style: GoogleFonts.fredoka(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  player,
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
            const SizedBox(height: 10),
            getHostName == widget.playerName
                ? AnimatedBuilder(
                    animation: buttonAnimation,
                    builder: (context, child) {
                      final scale = 1 + (buttonAnimation.value * 0.05);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (joinedPlayers.length <= 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "You Cannot Start the game with less than 3 Players 👀",
                                style: GoogleFonts.fredoka(),
                              ),
                              backgroundColor: Colors.yellow.shade700,
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, _, __) => GameCountDown(),
                              transitionsBuilder: (_, animation, __, child) {
                                return SlideTransition(
                                  position:
                                      Tween(
                                        begin: const Offset(1, 0),
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
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 50,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
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
                  )
                : SizedBox(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
