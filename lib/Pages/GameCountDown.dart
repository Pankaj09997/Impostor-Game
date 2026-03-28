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

  // Controls the big number scale-in effect
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Controls the ring/pulse expanding outward on each tick
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;
  late Animation<double> _ringOpacity;

  // Controls the overall fade-in on page load
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ── Scale animation for the number ──
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // ── Ring pulse animation ──
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringAnimation = Tween<double>(
      begin: 0.4,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));

    // ── Page fade-in ──
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Kick off first tick
    _playTick();
    _startCountdown();
  }

  // Plays the scale + ring animation on each number change
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
        Future.delayed(const Duration(milliseconds: 600), () {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isGo = count <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Background grid ──
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _GridPainter(),
          ),

          // ── Atmospheric glow — shifts color on GO ──
          Positioned(
            top: size.height * 0.2,
            left: size.width * 0.1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isGo ? Colors.green : const Color(0xFFE53935)).withOpacity(
                      0.15,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Expanding ring pulse ──
          Center(
            child: AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) {
                return Opacity(
                  opacity: _ringOpacity.value,
                  child: Transform.scale(
                    scale: _ringAnimation.value,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isGo
                              ? Colors.greenAccent
                              : const Color(0xFFE53935),
                          width: 2,
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
                  // ── Label above number ──
                  Text(
                    isGo ? "LET'S GO" : "STARTING IN",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white30,
                      fontSize: 13,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── The big number / GO ──
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.bebasNeue(
                        fontSize: isGo ? 160 : 200,
                        fontWeight: FontWeight.bold,
                        color: isGo ? Colors.greenAccent : Colors.white,
                        shadows: [
                          Shadow(
                            color:
                                (isGo
                                        ? Colors.greenAccent
                                        : const Color(0xFFE53935))
                                    .withOpacity(0.6),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: Text(
                        isGo ? "GO!" : "$count",
                        key: ValueKey(count),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Tick dots ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      // Dot is filled if countdown hasn't reached it yet
                      final filled = i < count;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: filled ? 10 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? const Color(0xFFE53935)
                                : Colors.white12,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle grid background ─────────────────────────────────────────────────
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
