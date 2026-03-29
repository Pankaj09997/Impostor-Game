import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/RoomPage.dart';

class VotingPage extends StatefulWidget {
  final String roomId;
  final String playerName;
  const VotingPage({super.key, required this.roomId, required this.playerName});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> with TickerProviderStateMixin {
  List<dynamic> playersList = [];
  Map<String, dynamic> votes = {};
  String? impostorName;
  String? impostorWord;
  String? crewmateWord;
  String? myVote;
  bool isVoting = false;

  /// True once we've shown the dialog — prevents double-showing
  bool _dialogShown = false;

  /// True once ONE device has written the result to Firestore
  bool _resolving = false;

  StreamSubscription? _subscription;

  // ── Timer ──
  static const int _totalSeconds = 60;
  int _secondsLeft = _totalSeconds;
  Timer? _countdownTimer;
  bool _timerStarted = false;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _timerPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _timerPulseController, curve: Curves.easeInOut),
    );

    _listenToRoom();
  }

  // ── Start 60-second local countdown ────────────────────────────────────────
  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      setState(() => _secondsLeft--);

      // Pulse ring when ≤ 10 s
      if (_secondsLeft <= 10 && _secondsLeft > 0) {
        _timerPulseController.forward(from: 0).then((_) {
          if (mounted) _timerPulseController.reverse();
        });
      }

      // Time's up — trigger resolve (only one device will win the race)
      if (_secondsLeft <= 0) {
        t.cancel();
        _resolveVotes();
      }
    });
  }

  // ── Listen to Firestore room doc ────────────────────────────────────────────
  void _listenToRoom() {
    _subscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;
          final data = snapshot.data()!;

          setState(() {
            playersList = List<dynamic>.from(data['players'] ?? []);
            votes = Map<String, dynamic>.from(data['votes'] ?? {});
            impostorName = data['impostorName'];
            impostorWord = data['impostorWord'];
            crewmateWord = data['crewmateWord'];
            myVote = votes[widget.playerName];
          });

          // Kick off the countdown as soon as we have players
          if (playersList.isNotEmpty && !_timerStarted) _startTimer();

          final result = data['result'];

          if (result != null && !_dialogShown) {
            // ── Result is written — show dialog on ALL devices ──
            _dialogShown = true;
            _countdownTimer?.cancel();
            _showResultDialog(result);
          } else if (result == null &&
              playersList.isNotEmpty &&
              votes.length == playersList.length &&
              !_resolving &&
              !_dialogShown) {
            // ── All players voted before time ran out — resolve immediately ──
            _countdownTimer?.cancel();
            _resolveVotes();
          }
        });
  }

  // ── Write result to Firestore (guarded so only one device wins) ────────────
  Future<void> _resolveVotes() async {
    if (_resolving || _dialogShown) return;
    _resolving = true;

    // Snapshot the current votes locally
    final currentVotes = Map<String, dynamic>.from(votes);
    final currentPlayers = List<dynamic>.from(playersList);
    final currentImpostor = impostorName;

    final Map<String, int> tally = {};
    for (final votedFor in currentVotes.values) {
      tally[votedFor.toString()] = (tally[votedFor.toString()] ?? 0) + 1;
    }

    final String accused = tally.isEmpty
        ? (currentPlayers.isNotEmpty
              ? currentPlayers[0].toString()
              : (currentImpostor ?? ''))
        : tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final result = accused == currentImpostor ? 'crewmate_win' : 'impostor_win';

    // Use a transaction so only the first writer wins; others see the
    // existing value and the Firestore listener handles showing the dialog
    try {
      final roomRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(roomRef);
        if (!snap.exists) return;
        // Only write if result not already set
        if (snap.data()!['result'] == null) {
          tx.update(roomRef, {'result': result, 'accused': accused});
        }
      });
    } catch (_) {
      // Transaction failed — another device already wrote; listener handles it
      _resolving = false;
    }
  }

  Future<void> _castVote(String votedFor) async {
    if (votedFor == widget.playerName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You can't vote for yourself 😅",
            style: GoogleFonts.fredoka(),
          ),
          backgroundColor: const Color(0xFFAA0A0A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (myVote != null) return;
    setState(() => isVoting = true);
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'votes.${widget.playerName}': votedFor});
    } finally {
      if (mounted) setState(() => isVoting = false);
    }
  }

  // ── Result dialog ───────────────────────────────────────────────────────────
  void _showResultDialog(String result) {
    final bool crewmateWon = result == 'crewmate_win';
    final bool iAmImpostor = widget.playerName == impostorName;

    final String personalEmoji;
    final String personalTitle;
    final String personalSub;

    if (crewmateWon) {
      if (iAmImpostor) {
        personalEmoji = "😬";
        personalTitle = "You got caught!";
        personalSub = "The crew saw through your lies, ${widget.playerName}!";
      } else {
        personalEmoji = "🎉";
        personalTitle = "You found them!";
        personalSub = "Great detective work, ${widget.playerName}!";
      }
    } else {
      if (iAmImpostor) {
        personalEmoji = "😈";
        personalTitle = "You fooled them all!";
        personalSub = "Masterful deception, ${widget.playerName}!";
      } else {
        personalEmoji = "😵";
        personalTitle = "You were deceived!";
        personalSub = "The impostor slipped right past you...";
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(personalEmoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                personalTitle,
                style: GoogleFonts.fredoka(
                  color: const Color(0xFFE53935),
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                personalSub,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  color: Colors.black45,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),
              // Global result pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: crewmateWon
                      ? const Color(0xFF2E7D32).withOpacity(0.08)
                      : const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: crewmateWon
                        ? const Color(0xFF2E7D32).withOpacity(0.25)
                        : const Color(0xFFE53935).withOpacity(0.25),
                  ),
                ),
                child: Text(
                  crewmateWon ? "🟢  Crewmates Win" : "🔴  Impostor Wins",
                  style: GoogleFonts.fredoka(
                    color: crewmateWon
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE53935),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Impostor reveal box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "The Impostor was",
                      style: GoogleFonts.fredoka(
                        color: Colors.black38,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      impostorName ?? '???',
                      style: GoogleFonts.fredoka(
                        color: const Color(0xFFE53935),
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _wordBox(
                            label: "Crewmate Word",
                            word: crewmateWord ?? '???',
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _wordBox(
                            label: "Impostor Word",
                            word: impostorWord ?? '???',
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, _, __) => RoomPage(
                        roomId: widget.roomId,
                        playerName: widget.playerName,
                      ),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    "Back to Lobby",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordBox({
    required String label,
    required String word,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.fredoka(
              color: color.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            word,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRing() {
    final progress = _secondsLeft / _totalSeconds;
    final isUrgent = _secondsLeft <= 10;

    return AnimatedBuilder(
      animation: _timerPulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: isUrgent ? _timerPulseAnimation.value : 1.0,
        child: child,
      ),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation(
                  Colors.white.withOpacity(0.2),
                ),
              ),
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_secondsLeft',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: isUrgent ? 22 : 20,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                Text(
                  'sec',
                  style: GoogleFonts.fredoka(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _countdownTimer?.cancel();
    _floatController.dispose();
    _fadeController.dispose();
    _timerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalVotes = votes.length;
    final totalPlayers = playersList.length;
    final hasVoted = myVote != null;
    final isUrgent = _secondsLeft <= 10;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUrgent
                ? [
                    const Color.fromARGB(255, 210, 70, 70),
                    const Color.fromARGB(255, 190, 30, 20),
                    const Color.fromARGB(255, 120, 5, 5),
                  ]
                : [
                    const Color.fromARGB(255, 239, 114, 114),
                    const Color.fromARGB(255, 229, 53, 47),
                    const Color.fromARGB(255, 170, 10, 10),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: size.height * 0.05,
              left: size.width * 0.1,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.07,
              left: 24,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value * 5),
                  child: _DecorDots(),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.10,
              right: 24,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -_floatAnimation.value * 5),
                  child: _DecorDots(opacity: 0.20),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Vote! 🗳️",
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                isUrgent
                                    ? "Hurry up! ⚡"
                                    : "$totalVotes / $totalPlayers voted",
                                style: GoogleFonts.fredoka(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _buildTimerRing(),
                        ],
                      ),
                    ),

                    // ── Subtitle ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hasVoted
                              ? "You voted for  $myVote  👀  waiting..."
                              : _dialogShown
                              ? "Time's up! Revealing results..."
                              : "Tap a player you think is the impostor",
                          style: GoogleFonts.fredoka(
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Vote progress bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: totalPlayers > 0
                              ? totalVotes / totalPlayers
                              : 0,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Player grid ──
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.05,
                            ),
                        itemCount: playersList.length,
                        itemBuilder: (context, index) {
                          final player = playersList[index].toString();
                          final isMe = player == widget.playerName;
                          final voteCount = votes.values
                              .where((v) => v == player)
                              .length;
                          final isVotedByMe = myVote == player;

                          return GestureDetector(
                            onTap:
                                isVoting ||
                                    hasVoted ||
                                    isMe ||
                                    _dialogShown ||
                                    _resolving
                                ? null
                                : () => _castVote(player),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isVotedByMe
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.15),
                                border: Border.all(
                                  color: isVotedByMe
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: isVotedByMe
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isVotedByMe
                                          ? const Color(0xFFE53935)
                                          : Colors.white.withOpacity(0.25),
                                    ),
                                    child: Center(
                                      child: Text(
                                        player[0].toUpperCase(),
                                        style: GoogleFonts.fredoka(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    player,
                                    style: GoogleFonts.fredoka(
                                      color: isVotedByMe
                                          ? const Color(0xFFE53935)
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isMe)
                                    Text(
                                      "you",
                                      style: GoogleFonts.fredoka(
                                        color: isVotedByMe
                                            ? Colors.black26
                                            : Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (voteCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isVotedByMe
                                            ? const Color(
                                                0xFFE53935,
                                              ).withOpacity(0.12)
                                            : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "$voteCount vote${voteCount > 1 ? 's' : ''}",
                                        style: GoogleFonts.fredoka(
                                          color: isVotedByMe
                                              ? const Color(0xFFE53935)
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 22),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        "playing as  ${widget.playerName} 👤",
                        style: GoogleFonts.fredoka(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13,
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
    );
  }
}

class _DecorDots extends StatelessWidget {
  final double opacity;
  const _DecorDots({this.opacity = 0.18});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Column(
        children: List.generate(3, (_) {
          return Row(
            children: List.generate(3, (__) {
              return Container(
                margin: const EdgeInsets.all(4),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
