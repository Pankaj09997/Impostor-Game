import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/RoomPage.dart';

class NamePage extends StatefulWidget {
  final String? roomId;
  final bool? isAdmin;
  const NamePage({super.key, this.roomId, this.isAdmin});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;
  late AnimationController _entryController;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _inputFade;
  late Animation<Offset> _inputSlide;
  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;
  final _formKey = GlobalKey<FormState>();
  bool _isJoining = false;
  bool _isReady = false;
  StreamSubscription? _subscription;
  List<dynamic> joinedPlayers = [];
  StreamSubscription? _roomSubscription;

  @override
  void initState() {
    super.initState();
    checkGameStatus();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _buttonController.repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        );

    _inputFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _inputSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _btnFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _entryController.forward();
  }

  void checkGameStatus() {
    _subscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) return;
          setState(() {
            _isReady = snapshot['status'] == 'ready';
          });
        });
  }

  Future<void> joinRoom(String name) async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomRef);

        if (!snapshot.exists) {
          throw Exception("Room does not exist");
        }

        final data = snapshot.data()!;
        final List<dynamic> players = data['players'] ?? [];

        if (players.contains(name)) {
          throw Exception("NAME_TAKEN");
        }

        if (players.length >= 10) {
          throw Exception("ROOM_FULL");
        }

        if (data['status'] == 'ready') {
          throw Exception("GAME_STARTED");
        }

        transaction.update(roomRef, {
          'players': FieldValue.arrayUnion([name]),
        });
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomPage(
            roomId: widget.roomId,
            isAdmin: widget.isAdmin,
            playerName: name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String message = "Something went wrong 😬";

      if (e.toString().contains("NAME_TAKEN")) {
        message = "That name's taken in this lobby 👀";
      } else if (e.toString().contains("ROOM_FULL")) {
        message = "The Room is already Full 👀";
      } else if (e.toString().contains("GAME_STARTED")) {
        message = "Game already started 😬";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.yellow.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(color: Colors.black87, fontSize: 16),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _buttonController.dispose();
    _entryController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Widget _nameInput() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          textAlign: TextAlign.center,
          maxLength: 10,
          validator: (value) {
            if (value == null || value.isEmpty) return "no_name";
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.fredoka(
            fontSize: 32,
            letterSpacing: 8,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.white.withOpacity(0.18),
            hintText: "Pick Your Name",
            hintStyle: GoogleFonts.fredoka(color: Colors.white38, fontSize: 24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.yellow.shade700, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.yellow.shade700, width: 2),
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),

        // ── Inline error pill ──
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (context, value, _) {
            final showError = value.text.isEmpty;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: showError
                  ? const SizedBox.shrink(key: ValueKey("empty"))
                  : const SizedBox.shrink(key: ValueKey("ok")),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "WHO ARE YOU?",
            style: GoogleFonts.fredoka(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 120),

              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            "What's your\nName?",
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 40,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        if (widget.roomId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.meeting_room_rounded,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Room  ${widget.roomId}",
                                  style: GoogleFonts.fredoka(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),
              FadeTransition(
                opacity: _inputFade,
                child: SlideTransition(
                  position: _inputSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _nameInput(),
                  ),
                ),
              ),

              const Spacer(),
              FadeTransition(
                opacity: _btnFade,
                child: SlideTransition(
                  position: _btnSlide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _buttonAnimation,
                          builder: (context, child) => Transform.scale(
                            scale: _isJoining ? 1.0 : _buttonAnimation.value,
                            child: child,
                          ),
                          child: GestureDetector(
                            onTap: _isJoining
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isJoining = true);
                                      try {
                                        final name = _nameController.text
                                            .trim();
                                        await joinRoom(name);
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor:
                                                Colors.yellow.shade700,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            content: Text(
                                              "Something went wrong 😬 Try again",
                                              style: GoogleFonts.fredoka(
                                                color: Colors.black87,
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isJoining = false);
                                        }
                                      }
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
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
                                  if (_isJoining)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFFE53935),
                                      ),
                                    )
                                  else
                                    const Text(
                                      "🎮",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isJoining ? "Joining..." : "Join Game",
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
                        ),

                        const SizedBox(height: 14),

                        Text(
                          "max 10 characters for your name 👀",
                          style: GoogleFonts.fredoka(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
