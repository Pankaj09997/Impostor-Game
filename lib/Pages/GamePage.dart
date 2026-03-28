import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_tap_to_exit/double_tap_to_exit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/VotingPage.dart';
import 'package:scratcher/widgets.dart';

class GamePage extends StatefulWidget {
  final String playerName;
  final String roomId;
  const GamePage({super.key, required this.playerName, required this.roomId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  String? impWord;
  String? impMeaning;
  String? crewmateWords;
  String? crewmateWordMeanings;
  String? category;
  String? impostorName;
  bool isImpostor = false;
  bool isLoading = true;
  bool hasScratched = false;
  bool isRevealing = false;
  double scratchProgress = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    getGameData();
  }

  Future<void> getGameData() async {
    final docRef = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();

    setState(() {
      category = docRef['category'];
      impostorName = docRef['impostorName'];
      if (widget.playerName == impostorName) {
        isImpostor = true;
        impWord = docRef['impostorWord'];
        impMeaning = docRef['impostorWordMeaning'];
      } else {
        isImpostor = false;
        crewmateWords = docRef['crewmateWord'];
        crewmateWordMeanings = docRef['crewmateWordMeaning'];
      }
      isLoading = false;
    });

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get displayWord =>
      isImpostor ? (impWord ?? '') : (crewmateWords ?? '');
  String get displayMeaning =>
      isImpostor ? (impMeaning ?? '') : (crewmateWordMeanings ?? '');

  Widget _buildExposeButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, _, __) => VotingPage(
              roomId: widget.roomId,
              playerName: widget.playerName,
            ),
            transitionDuration: Duration.zero,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: hasScratched ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                "EXPOSE THE IMPOSTOR",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return DoubleTapToExit(
      snackBar: SnackBar(
        content: Text(
          'Press back again to exit',
          style: GoogleFonts.spaceGrotesk(),
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
                  // ── AppBar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        if (category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE53935).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.category_rounded,
                                  color: Color(0xFFE53935),
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category!.toUpperCase(),
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFE53935),
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isImpostor
                                ? const Color(0xFFE53935).withOpacity(0.15)
                                : Colors.greenAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isImpostor
                                  ? const Color(0xFFE53935).withOpacity(0.4)
                                  : Colors.greenAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isImpostor
                                      ? const Color(0xFFE53935)
                                      : Colors.greenAccent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isImpostor ? "IMPOSTOR" : "CREWMATE",
                                style: GoogleFonts.spaceGrotesk(
                                  color: isImpostor
                                      ? const Color(0xFFE53935)
                                      : Colors.greenAccent,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (isLoading)
                    const CircularProgressIndicator(
                      color: Color(0xFFE53935),
                      strokeWidth: 2,
                    )
                  else
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              hasScratched
                                  ? "YOUR SECRET WORD"
                                  : "SCRATCH TO REVEAL",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white30,
                                fontSize: 11,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 20),

                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: hasScratched
                                      ? 1.0
                                      : _pulseAnimation.value,
                                  child: child,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isImpostor
                                        ? const Color(
                                            0xFFE53935,
                                          ).withOpacity(0.4)
                                        : Colors.greenAccent.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isImpostor
                                                  ? const Color(0xFFE53935)
                                                  : Colors.greenAccent)
                                              .withOpacity(0.12),
                                      blurRadius: 32,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Scratcher(
                                    brushSize: 38,
                                    threshold: 50,
                                    color: const Color(0xFFE53935),
                                    image: Image.asset(
                                      'assets/scratch_texture.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFE53935),
                                      ),
                                    ),
                                    onChange: (value) {
                                      setState(() {
                                        scratchProgress = value;
                                        if (value >= 50 && !hasScratched) {
                                          hasScratched = true;
                                          _pulseController.stop();
                                          // restart for the expose button
                                          _pulseController.repeat(
                                            reverse: true,
                                          );
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: size.width - 48,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 48,
                                        horizontal: 28,
                                      ),
                                      color: const Color(0xFF161616),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            displayWord,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.bebasNeue(
                                              color: Colors.white,
                                              fontSize: 48,
                                              letterSpacing: 6,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            height: 1,
                                            width: 60,
                                            color: Colors.white12,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            displayMeaning,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white54,
                                              fontSize: 15,
                                              height: 1.5,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Progress bar (before scratch) ──
                            if (!hasScratched) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: scratchProgress / 100,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.07,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFE53935),
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${scratchProgress.toStringAsFixed(0)}% revealed",
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white24,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],

                            // ── Post-scratch hint ──
                            if (hasScratched)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isImpostor
                                          ? Icons.visibility_off_rounded
                                          : Icons.groups_rounded,
                                      color: Colors.white30,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isImpostor
                                          ? "Blend in. Don't get caught."
                                          : "Discuss. Find the impostor.",
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // ── Expose button — only shown after scratching ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: hasScratched
                        ? Padding(
                            key: const ValueKey('expose'),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildExposeButton(),
                          )
                        : const SizedBox.shrink(key: ValueKey('hidden')),
                  ),

                  // ── Bottom player tag ──
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(
                      "playing as  ${widget.playerName.toUpperCase()}",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white12,
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
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
