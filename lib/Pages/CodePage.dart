import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:impostorgame/Pages/InputFormatters/TextFormatters.dart';
import 'package:impostorgame/Pages/NamePage.dart';
import 'package:impostorgame/Pages/WaitingLobby.dart';

class CodePage extends StatefulWidget {
  const CodePage({super.key});

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late Animation<double> _buttonAnimation;
  late AnimationController _buttonController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_buttonController);
    _startAnimation();
  }

  void _startAnimation() async {
    await _buttonController.repeat(reverse: true);
  }

  Future<void> checkAvailableRoom() async {}

  Widget codeInput() {
    return Column(
      children: [
        TextFormField(
          controller: _codeController,
          textAlign: TextAlign.center,
          inputFormatters: [UpperCaseTextFormatter()],
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) return "no_code";
            if (value.length < 6) return "short_code";
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.fredoka(
            fontSize: 32,
            letterSpacing: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            hintText: "_ _ _ _ _ _",
            hintStyle: GoogleFonts.fredoka(
              letterSpacing: 10,
              color: Colors.white38,
              fontSize: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white24, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.yellow, width: 2.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.yellow, width: 2.5),
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            errorMaxLines: 1,
          ),
        ),

        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _codeController,
          builder: (context, value, _) {
            String? errorMsg;
            if (value.text.isEmpty) {
              errorMsg = null;
            } else if (value.text.length < 6) {
              errorMsg = "That doesn't look right 🤨";
            }

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
                          boxShadow: [
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
    _codeController.dispose();
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
          title: Padding(
            padding: EdgeInsetsGeometry.fromLTRB(50, 0, 0, 0),
            child: Text(
              "Join The Room",
              style: GoogleFonts.fredoka(color: Colors.white),
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            SizedBox(height: 20),
            Padding(padding: const EdgeInsets.all(16.0), child: codeInput()),
            SizedBox(height: 20),
            AnimatedBuilder(
              animation: _buttonAnimation,
              builder: (context, child) {
                final scale = 1 + (_buttonAnimation.value * 0.05);
                return Transform.scale(scale: scale, child: child);
              },
              child: GestureDetector(
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    final code = _codeController.text.trim();
                    final doc = await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(code)
                        .get();
                    if (!mounted) return;
                    if (doc.exists) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) =>
                              NamePage(roomId: code, isAdmin: false),
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position:
                                  Tween(
                                    begin: Offset(1, 0),
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Room not found 👀",
                            style: GoogleFonts.fredoka(),
                          ),
                          backgroundColor: Colors.yellow.shade700,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 50),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
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
