import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/GamePage.dart';

class GameCountDown extends StatefulWidget {
  final String playerName;
  final String roomId;
  const GameCountDown({
    super.key,
    required this.playerName,
    required this.roomId,
  });

  @override
  State<GameCountDown> createState() => _GameCountDownState();
}

class _GameCountDownState extends State<GameCountDown>
    with TickerProviderStateMixin {
  int count = 3;

  // Controls the big number scale-in (bouncy elastic)
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Controls a soft "pop" ring that expands then fades
  late AnimationController _ringController;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  // Page fade-in on load
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Floating bob for the dots / decoration
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // ── Bouncy scale for the number ──
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
    ]).animate(_scaleController);

    // ── Ring pulse ──
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringScale = Tween<double>(
      begin: 0.5,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));

    // ── Page fade-in ──
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // ── Gentle float for decoration ──
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);

    _playTick();
    _startCountdown();
  }

  void _playTick() {
    _scaleController.forward(from: 0);
    _ringController.forward(from: 0);
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => count--);
      _playTick();

      if (count > 0) {
        _startCountdown();
      } else {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, _, __) => GamePage(
                playerName: widget.playerName,
                roomId: widget.roomId,
              ),
              transitionDuration: Duration.zero,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _ringController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isGo = count <= 0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Same red gradient as Splash & Homepage
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
            // ── Soft white blob glow in background ──
            Positioned(
              top: size.height * 0.15,
              left: size.width * 0.1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(isGo ? 0.18 : 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating decorative dots (top-left) ──
            Positioned(
              top: size.height * 0.08,
              left: 28,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, _) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value * 6),
                  child: _DecorDots(),
                ),
              ),
            ),

            // ── Floating decorative dots (bottom-right) ──
            Positioned(
              bottom: size.height * 0.10,
              right: 28,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, _) => Transform.translate(
                  offset: Offset(0, -_floatAnimation.value * 6),
                  child: _DecorDots(opacity: 0.25),
                ),
              ),
            ),

            // ── Expanding ring pulse (white, playful) ──
            Center(
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _ringOpacity.value,
                    child: Transform.scale(
                      scale: _ringScale.value,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.7),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Main content ──
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Label ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isGo ? "HERE WE GO!" : "STARTING IN",
                        key: ValueKey(isGo),
                        style: GoogleFonts.fredoka(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 16,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ── Big number / GO ──
                    Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: GoogleFonts.fredoka(
                            fontSize: isGo ? 130 : 180,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.20),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            isGo ? "GO! 🎉" : "$count",
                            key: ValueKey(count),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Pill-style progress dots ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i < count;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: active ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 40),

                    // ── Friendly sub-label ──
                    AnimatedOpacity(
                      opacity: isGo ? 0.0 : 0.55,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        "Get ready, ${widget.playerName}! 👀",
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
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
