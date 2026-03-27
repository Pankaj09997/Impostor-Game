import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/CodePage.dart';
import 'package:impostorgame/Pages/NamePage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  late Animation<double> _imageVibration;
  late AnimationController _imageController;
  late Animation<double> _pulseAnimation;
  late AnimationController _pulseController;
  late Animation<double> _fadeInAnimation;
  late AnimationController _fadeInController;
  bool _isCreatingRoom = false;

  String createRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<String> saveRoomId() async {
    final roomId = createRoomId();
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'roomId': roomId,
      'players': [],
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return roomId;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
    );

    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _imageVibration = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeInOut),
    );
    _imageController.repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
    _fadeInController.forward();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _pulseController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  void _navigate(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, _, __) => page,
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Atmospheric background glow ──
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE53935).withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE53935).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Subtle grid lines ──
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: _GridPainter(),
          ),

          // ── Main content ──
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  // AppBar area
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "THE LOBBY",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── SVG image with float effect ──
                  AnimatedBuilder(
                    animation: _imageVibration,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _imageVibration.value * 6),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SvgPicture.asset(
                        "assets/SplashImage.svg",
                        height: 240,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Tagline ──
                  Text(
                    "WHO'S HIDING?",
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFFE53935),
                      fontSize: 42,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Lie. Blend in. Survive.",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white38,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const Spacer(),

                  // ── Buttons ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        // Primary: Create Room
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: _PrimaryButton(
                            label: _isCreatingRoom
                                ? "CREATING..."
                                : "CREATE ROOM",
                            icon: Icons.add_circle_outline_rounded,
                            isLoading: _isCreatingRoom,
                            onTap: _isCreatingRoom
                                ? null
                                : () async {
                                    setState(() => _isCreatingRoom = true);
                                    try {
                                      final roomId = await saveRoomId();
                                      if (!mounted) return;
                                      _navigate(
                                        NamePage(roomId: roomId, isAdmin: true),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Couldn't create room 😬 Try again",
                                            style: GoogleFonts.spaceGrotesk(),
                                          ),
                                          backgroundColor: const Color(
                                            0xFFE53935,
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted)
                                        setState(() => _isCreatingRoom = false);
                                    }
                                  },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Secondary: Join Room
                        _SecondaryButton(
                          label: "JOIN ROOM",
                          icon: Icons.login_rounded,
                          onTap: () => _navigate(const CodePage()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary Button ──────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
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
    );
  }
}

// ── Secondary Button ─────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
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
