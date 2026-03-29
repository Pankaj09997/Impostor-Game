import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/GameCountDown.dart';
import 'package:impostorgame/Words/words.dart';

const _kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color.fromARGB(255, 239, 114, 114),
    Color.fromARGB(255, 229, 53, 47),
    Color.fromARGB(255, 170, 10, 10),
  ],
);

const _kTint = Color(0xFFFFE0E0);
const _kAccent = Color(0xFFE53535);

class _GradBox extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  const _GradBox({
    required this.child,
    required this.borderRadius,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: _kGradient,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
    ),
    child: child,
  );
}

class _GradText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _GradText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (b) =>
        _kGradient.createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
    blendMode: BlendMode.srcIn,
    child: Text(text, style: style.copyWith(color: Colors.white)),
  );
}

class RoomPage extends StatefulWidget {
  final String? roomId;
  final bool? isAdmin;
  final String? playerName;
  const RoomPage({super.key, this.roomId, this.isAdmin, this.playerName});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with TickerProviderStateMixin {
  List<dynamic> joinedPlayers = [];
  late AnimationController _pulseController;
  late AnimationController _dotController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dotAnimation;
  StreamSubscription? _roomSubscription;
  late final AppLifecycleListener appLifecycleListener;
  String? getHostName;
  bool _hasNavigated = false;

  static const List<Color> _avatarBg = [
    Color(0xFFFFD6D6),
    Color(0xFFFFE5CC),
    Color(0xFFD6F0FF),
    Color(0xFFD6FFE8),
    Color(0xFFEFD6FF),
    Color(0xFFFFD6F0),
    Color(0xFFD6ECFF),
    Color(0xFFFFF3D6),
    Color(0xFFD6FFF6),
    Color(0xFFFFDDD6),
  ];
  static const List<Color> _avatarFg = [
    Color(0xFFB71C1C),
    Color(0xFFBF360C),
    Color(0xFF0D47A1),
    Color(0xFF1B5E20),
    Color(0xFF4A148C),
    Color(0xFF880E4F),
    Color(0xFF006064),
    Color(0xFFE65100),
    Color(0xFF004D40),
    Color(0xFFBF360C),
  ];

  @override
  void initState() {
    super.initState();
    HostName();
    gethostName();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _dotAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dotController, curve: Curves.easeInOut));
    _dotController.repeat(reverse: true);

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
        final List<dynamic> remaining = data['players'] ?? [];
        if (widget.playerName == currentHost) await changeHost(remaining);
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
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
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
    setState(() => getHostName = data['hostName']);
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
        players.isNotEmpty
            ? await roomRef.update({
                'hostName': players.first,
                'players': players,
              })
            : await roomRef.delete();
      } else {
        await roomRef.update({'players': players});
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> changeHost(List<dynamic> remaining) async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId);
    remaining.isNotEmpty
        ? await roomRef.update({'hostName': remaining.first})
        : await roomRef.delete();
  }

  Future<void> startGame() async {
    if (joinedPlayers.length < 4 || joinedPlayers.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF7F0000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          content: Text(
            "Need 4–10 players to start 👀",
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }
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
    _pulseController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHost = getHostName == widget.playerName;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _removePlayerAndLeave();
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,

          decoration: const BoxDecoration(gradient: _kGradient),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _removePlayerAndLeave,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _dotAnimation,
                              builder: (context, _) => Opacity(
                                opacity: _dotAnimation.value,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "LIVE",
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 13,
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "The Chamber 🕵️",
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("🔑", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            _GradText(
                              widget.roomId ?? "------",
                              style: GoogleFonts.fredoka(
                                fontSize: 28,
                                letterSpacing: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                "Players",
                                style: GoogleFonts.fredoka(
                                  color: const Color(0xFF1A1A1A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _kTint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: _GradText(
                                  "${joinedPlayers.length}/10",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "min 4 to start",
                                style: GoogleFonts.fredoka(
                                  color: Colors.black38,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Expanded(
                          child: joinedPlayers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "⏳",
                                        style: TextStyle(fontSize: 52),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Waiting for players...",
                                        style: GoogleFonts.fredoka(
                                          color: Colors.black38,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: joinedPlayers.length,
                                  itemBuilder: (context, index) {
                                    final player = joinedPlayers[index];
                                    final isPlayerHost = player == getHostName;
                                    final isMe = player == widget.playerName;
                                    final ci = index % _avatarBg.length;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: isPlayerHost
                                                ? _kAccent.withOpacity(0.3)
                                                : const Color(0xFFEEE0E0),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.04,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            if (isPlayerHost)
                                              _GradBox(
                                                borderRadius:
                                                    BorderRadius.circular(23),
                                                child: SizedBox(
                                                  width: 46,
                                                  height: 46,
                                                  child: Center(
                                                    child: Text(
                                                      player[0].toUpperCase(),
                                                      style:
                                                          GoogleFonts.fredoka(
                                                            color: Colors.white,
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                width: 46,
                                                height: 46,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _avatarBg[ci],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    player[0].toUpperCase(),
                                                    style: GoogleFonts.fredoka(
                                                      color: _avatarFg[ci],
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            const SizedBox(width: 14),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    player,
                                                    style: GoogleFonts.fredoka(
                                                      color: const Color(
                                                        0xFF1A1A1A,
                                                      ),
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (isPlayerHost)
                                                    _GradText(
                                                      "host 👑",
                                                      style:
                                                          GoogleFonts.fredoka(
                                                            fontSize: 13,
                                                          ),
                                                    )
                                                  else if (isMe)
                                                    Text(
                                                      "you 👋",
                                                      style:
                                                          GoogleFonts.fredoka(
                                                            color:
                                                                Colors.black38,
                                                            fontSize: 13,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            if (isPlayerHost)
                                              _GradBox(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 5,
                                                    ),
                                                child: Text(
                                                  "HOST",
                                                  style: GoogleFonts.fredoka(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    letterSpacing: 1,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.green.shade400,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          child: isHost
                              ? AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) => Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: child,
                                  ),
                                  child: GestureDetector(
                                    onTap: startGame,
                                    child: _GradBox(
                                      borderRadius: BorderRadius.circular(20),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                            255,
                                            229,
                                            53,
                                            47,
                                          ).withOpacity(0.45),
                                          blurRadius: 22,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            "🎮",
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Start Game",
                                            style: GoogleFonts.fredoka(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _kAccent.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _dotAnimation,
                                        builder: (context, _) => Opacity(
                                          opacity: _dotAnimation.value,
                                          child: const Text(
                                            "⏳",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Waiting for host...",
                                        style: GoogleFonts.fredoka(
                                          color: Colors.black38,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
