import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VotingPage extends StatefulWidget {
  final String roomId;
  final String playerName;
  const VotingPage({super.key, required this.roomId, required this.playerName});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  List<dynamic> playersList = [];
  Map<String, dynamic> votes = {};
  String? impostorName;
  String? impostorWord;
  String? crewmateWord;
  String? myVote;
  bool isVoting = false;
  bool gameResolved = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToRoom();
  }

  void _listenToRoom() {
    _subscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;
          final data = snapshot.data()!;

          setState(() {
            playersList = data['players'] ?? [];
            votes = Map<String, dynamic>.from(data['votes'] ?? {});
            impostorName = data['impostorName'];
            impostorWord = data['impostorWord'];
            crewmateWord = data['crewmateWord'];
            // restore my vote if I already voted
            myVote = votes[widget.playerName];
          });

          // check if everyone has voted
          final result = data['result'];
          if (result != null && !gameResolved) {
            setState(() => gameResolved = true);
            _showResultDialog(result);
          } else if (result == null &&
              playersList.isNotEmpty &&
              votes.length == playersList.length &&
              !gameResolved) {
            _resolveVotes();
          }
        });
  }

  // ── Count votes and decide winner ────────────────────────────────────────
  Future<void> _resolveVotes() async {
    // Count how many votes each player received
    final Map<String, int> tally = {};
    for (final votedFor in votes.values) {
      tally[votedFor] = (tally[votedFor] ?? 0) + 1;
    }

    // Find the most voted player
    String accused = tally.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    // Compare to actual impostor
    final result = accused == impostorName ? 'crewmate_win' : 'impostor_win';

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .update({'result': result, 'accused': accused});
  }

  // ── Cast vote ─────────────────────────────────────────────────────────────
  Future<void> _castVote(String votedFor) async {
    // Prevent voting for yourself
    if (votedFor == widget.playerName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You can't vote for yourself 😅",
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Already voted — do nothing
    if (myVote != null) return;

    setState(() => isVoting = true);

    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            // votes is a map: voterName → votedForName
            'votes.${widget.playerName}': votedFor,
          });
    } finally {
      if (mounted) setState(() => isVoting = false);
    }
  }

  // ── Result dialog ─────────────────────────────────────────────────────────
  void _showResultDialog(String result) {
    final bool crewmateWon = result == 'crewmate_win';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: crewmateWon
                  ? Colors.greenAccent.withOpacity(0.4)
                  : const Color(0xFFE53935).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (crewmateWon ? Colors.greenAccent : const Color(0xFFE53935))
                        .withOpacity(0.15),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ──
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (crewmateWon
                              ? Colors.greenAccent
                              : const Color(0xFFE53935))
                          .withOpacity(0.12),
                  border: Border.all(
                    color:
                        (crewmateWon
                                ? Colors.greenAccent
                                : const Color(0xFFE53935))
                            .withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  crewmateWon
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_very_dissatisfied_rounded,
                  color: crewmateWon
                      ? Colors.greenAccent
                      : const Color(0xFFE53935),
                  size: 30,
                ),
              ),

              const SizedBox(height: 20),

              // ── Result title ──
              Text(
                crewmateWon ? "CREWMATES WIN!" : "IMPOSTOR WINS!",
                style: GoogleFonts.bebasNeue(
                  color: crewmateWon
                      ? Colors.greenAccent
                      : const Color(0xFFE53935),
                  fontSize: 42,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                crewmateWon
                    ? "The impostor has been caught"
                    : "The crew was deceived",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 24),

              // ── Impostor reveal ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(
                      "THE IMPOSTOR WAS",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white24,
                        fontSize: 10,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      impostorName ?? '???',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 36,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // word comparison
                    Row(
                      children: [
                        Expanded(
                          child: _wordBox(
                            label: "CREWMATE WORD",
                            word: crewmateWord ?? '???',
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _wordBox(
                            label: "IMPOSTOR WORD",
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

              // ── Close ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    "CLOSE",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54,
                      fontSize: 13,
                      letterSpacing: 3,
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
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: color.withOpacity(0.6),
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            word,
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              color: color,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalVotes = votes.length;
    final totalPlayers = playersList.length;
    final hasVoted = myVote != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Glows ──
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

          SafeArea(
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
                      Text(
                        "VOTE",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // votes progress pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          "$totalVotes / $totalPlayers voted",
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Subtitle ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    hasVoted
                        ? "You voted for  $myVote  — waiting for others..."
                        : "Tap a player to vote them as the impostor",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white30,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Vote progress bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalPlayers > 0 ? totalVotes / totalPlayers : 0,
                      backgroundColor: Colors.white.withOpacity(0.07),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFE53935),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Player grid ──
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: playersList.length,
                    itemBuilder: (context, index) {
                      final player = playersList[index].toString();
                      final isMe = player == widget.playerName;

                      // how many votes this player has received
                      final voteCount = votes.values
                          .where((v) => v == player)
                          .length;

                      final isVotedByMe = myVote == player;

                      return GestureDetector(
                        onTap: isVoting || hasVoted || isMe
                            ? null
                            : () => _castVote(player),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isVotedByMe
                                ? const Color(0xFFE53935).withOpacity(0.12)
                                : Colors.white.withOpacity(0.04),
                            border: Border.all(
                              color: isVotedByMe
                                  ? const Color(0xFFE53935).withOpacity(0.5)
                                  : isMe
                                  ? Colors.white24
                                  : Colors.white12,
                              width: isVotedByMe ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── Avatar ──
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isVotedByMe
                                      ? const Color(0xFFE53935)
                                      : Colors.white.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    player[0].toUpperCase(),
                                    style: GoogleFonts.bebasNeue(
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ── Name ──
                              Text(
                                player,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              // ── YOU tag ──
                              if (isMe)
                                Text(
                                  "YOU",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white30,
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                              const SizedBox(height: 6),

                              // ── Vote count badge ──
                              if (voteCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE53935,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE53935,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    "$voteCount vote${voteCount > 1 ? 's' : ''}",
                                    style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFFE53935),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
