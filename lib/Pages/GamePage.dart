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
  double scratchProgress = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);

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
    _floatController.dispose();
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
        builder: (context, child) => Transform.scale(
          scale: hasScratched ? _pulseAnimation.value : 1.0,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🕵️", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                "Expose the Impostor",
                style: GoogleFonts.fredoka(
                  color: const Color(0xFFE53935),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
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
        content: Text('Press back again to exit', style: GoogleFonts.fredoka()),
        backgroundColor: const Color(0xFFAA0A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,

          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 239, 114, 114),
                Color.fromARGB(255, 229, 53, 47),
                Color.fromARGB(255, 170, 10, 10),
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Soft white glow blob ──
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

              // ── Decorative dots top-left ──
              Positioned(
                top: size.height * 0.07,
                left: 24,
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, _) => Transform.translate(
                    offset: Offset(0, _floatAnimation.value * 5),
                    child: _DecorDots(),
                  ),
                ),
              ),

              // ── Decorative dots bottom-right ──
              Positioned(
                bottom: size.height * 0.12,
                right: 24,
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, _) => Transform.translate(
                    offset: Offset(0, -_floatAnimation.value * 5),
                    child: _DecorDots(opacity: 0.20),
                  ),
                ),
              ),

              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    // ── Top bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  isImpostor ? "🔴" : "🟢",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isImpostor ? "Impostor" : "Crewmate",
                                  style: GoogleFonts.fredoka(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
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
                        color: Colors.white,
                        strokeWidth: 2.5,
                      )
                    else
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // ── Label above card ──
                              Text(
                                hasScratched
                                    ? "Your secret word 🤫"
                                    : "Scratch to reveal 👇",
                                style: GoogleFonts.fredoka(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── Scratch card ──
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) => Transform.scale(
                                  scale: hasScratched
                                      ? 1.0
                                      : _pulseAnimation.value,
                                  child: child,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
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
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: size.width - 48,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 44,
                                          horizontal: 28,
                                        ),
                                        color: Colors.white,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              displayWord,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.fredoka(
                                                color: const Color(0xFFE53935),
                                                fontSize: 52,
                                                fontWeight: FontWeight.w700,
                                                height: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Container(
                                              height: 1.5,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFE53935,
                                                ).withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              displayMeaning,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.fredoka(
                                                color: Colors.black54,
                                                fontSize: 16,
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

                              const SizedBox(height: 22),

                              // ── Scratch progress bar ──
                              if (!hasScratched) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: scratchProgress / 100,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.25,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                    minHeight: 5,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  "${scratchProgress.toStringAsFixed(0)}% revealed",
                                  style: GoogleFonts.fredoka(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],

                              // ── Post-scratch hint pill ──
                              if (hasScratched)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isImpostor
                                        ? "🤫 Blend in. Don't get caught!"
                                        : "🧐 Discuss. Find the impostor!",
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // ── Expose button — slides in after scratch ──
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
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildExposeButton(),
                            )
                          : const SizedBox.shrink(key: ValueKey('hidden')),
                    ),

                    // ── Bottom player tag ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        "playing as  ${widget.playerName} 👤",
                        style: GoogleFonts.fredoka(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small decorative dot cluster ─────────────────────────────────────────────
class _DecorDots extends StatelessWidget {
  final double opacity;
  const _DecorDots({this.opacity = 0.18});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Column(
        children: List.generate(3, (row) {
          return Row(
            children: List.generate(3, (col) {
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
