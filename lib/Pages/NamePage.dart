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

class _NamePageState extends State<NamePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late Animation<double> _buttonAnimation;
  late AnimationController _buttonController;
  final _formKey = GlobalKey<FormState>();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _buttonController.repeat(reverse: true);
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
            fillColor: Colors.white.withOpacity(0.15),
            hintText: "your name...",
            hintStyle: GoogleFonts.fredoka(color: Colors.white38, fontSize: 24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white24, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.yellow, width: 2.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.yellow, width: 2.5),
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),

        // ✅ inline error pill — same pattern as CodePage
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (context, value, _) {
            String? errorMsg;
            if (value.text.isEmpty) errorMsg = null;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: errorMsg != null
                  ? Padding(
                      key: ValueKey(errorMsg),
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade700,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          errorMsg,
                          style: GoogleFonts.fredoka(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey("empty")),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: Colors.redAccent,
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          elevation: 0,
          // ✅ added appBar to match other pages
          title: Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 0, 0),
            child: Text(
              "Who Are You?",
              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 24),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),

            // ✅ room ID pill — shows which room they're joining
            if (widget.roomId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.meeting_room,
                        color: Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Room  ${widget.roomId}",
                        style: GoogleFonts.fredoka(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(padding: const EdgeInsets.all(16.0), child: _nameInput()),

            const SizedBox(height: 20),

            // ✅ animated button with loading spinner — matches HomePage/CodePage pattern
            AnimatedBuilder(
              animation: _buttonAnimation,
              builder: (context, child) {
                final scale = 1 + (_buttonAnimation.value * 0.05);
                return Transform.scale(scale: scale, child: child);
              },
              child: GestureDetector(
                onTap: _isJoining
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isJoining = true);
                          try {
                            final name = _nameController.text.trim();

                            final roomDoc = await FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(widget.roomId)
                                .get();

                            if (!mounted) return;

                            final List<dynamic> currentPlayers =
                                roomDoc['players'] ?? [];

                            if (currentPlayers.contains(name)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.yellow.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  content: Text(
                                    "That name's taken in this lobby 👀",
                                    style: GoogleFonts.fredoka(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                              return;
                            }

                            await FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(widget.roomId)
                                .update({
                                  'players': FieldValue.arrayUnion([name]),
                                });

                            if (!mounted) return;

                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, _, __) => RoomPage(
                                  roomId: widget.roomId,
                                  isAdmin: widget.isAdmin,
                                  playerName: name,
                                ),
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
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.yellow.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
                            if (mounted) setState(() => _isJoining = false);
                          }
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
                  // ✅ loading spinner replaces text while joining
                  child: _isJoining
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "Join Game",
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
