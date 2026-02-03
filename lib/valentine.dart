import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart'; // Add: audioplayers
import 'package:confetti/confetti.dart'; // Add: confetti
import 'dart:math';

class ValentineView extends StatefulWidget {
  const ValentineView({super.key});

  @override
  State<ValentineView> createState() => _ValentineViewState();
}

class _ValentineViewState extends State<ValentineView>
    with TickerProviderStateMixin {
  // Logic States
  bool hasStarted = false; // New: To handle the start screen
  int noCount = 0;
  bool isAccepted = false;

  late AudioPlayer _audioPlayer;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  bool _isPlayingSadMusic = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Removed _playTrack from initState to comply with Browser Autoplay policies
  }

  Future<void> _playTrack(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onStartApp() {
    setState(() => hasStarted = true);
    _playTrack('music/ready_for_it.mp3'); // Unlocks audio on first click
  }

  void _onNoTapped() {
    _shakeController.forward(from: 0.0);
    HapticFeedback.lightImpact();

    setState(() {
      noCount++;
      if (noCount >= 3 && !_isPlayingSadMusic) {
        _isPlayingSadMusic = true;
        _playTrack('music/mean.mp3');
      }
    });
  }

  void _onYesTapped() {
    setState(() => isAccepted = true);
    _confettiController.play();
    _playTrack('music/you_belong_with_me.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F3),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: !hasStarted
                ? _buildStartScreen()
                : Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: isAccepted
                          ? _buildSuccessView()
                          : _buildProposalView(),
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              colors: const [Colors.pink, Colors.red, Colors.white],
              numberOfParticles: 30,
              gravity: 0.1,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: THE START OVERLAY ---
  Widget _buildStartScreen() {
    return Container(
      key: const ValueKey('start_screen'),
      width: double.infinity,
      color: const Color(0xFFFFF0F3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, color: Colors.pinkAccent, size: 100),
          const SizedBox(height: 20),
          const Text(
            "You have a new message!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _onStartApp,
            child: const Text(
              "Open My Card",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/gif/bear-kiss.gif', width: 250, height: 250),
        const SizedBox(height: 20),
        const Text(
          'YAYAYAYAYA!',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'Ek bar aur pata liya 😌',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProposalView() {
    bool shouldStack = noCount > 3;
    final List<String> noTexts = [
      "No",
      "Sure?",
      "Sochlo..",
      "Last chance!",
      "Wait!",
      "Maanjaa 😡",
      "Pls",
      "Pls 🥺",
      "Pls 🥺🥺",
      "Pls 🥺🥺🥺",
    ];
    String currentNoText = noCount < noTexts.length
        ? noTexts[noCount]
        : noTexts.last;

    return SingleChildScrollView(
      key: const ValueKey('proposal'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Image.asset('assets/gif/jumping-bear.gif', width: 200, height: 200),
          const Text(
            'Will you be my Valentine?',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Flex(
            direction: shouldStack ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YesBttn(noCount: noCount, onTap: _onYesTapped),
              if (!shouldStack)
                const SizedBox(width: 15)
              else
                const SizedBox(height: 15),
              _buildAnimatedNoButton(currentNoText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNoButton(String text) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double shakeX = (0.5 - _shakeController.value).abs() * 15;
        return Transform.translate(
          offset: Offset(noCount >= 3 ? shakeX : 0, 0),
          child: NoBttn(noCount: noCount, text: text, onTap: _onNoTapped),
        );
      },
    );
  }
}

/// --- YES BUTTON ---
class YesBttn extends StatelessWidget {
  const YesBttn({super.key, required this.noCount, required this.onTap});
  final int noCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double growth = 1.0 + (noCount * 0.45);
    return CommonButtonBase(
      onTap: onTap,
      color: Colors.green,
      text: "Yes",
      width: (110 * growth).clamp(110, 300),
      height: (60 * growth).clamp(60, 200),
      fontSize: (18 * growth).clamp(18, 45),
      padding: 16.0,
    );
  }
}

/// --- NO BUTTON (The Shrinking One) ---
class NoBttn extends StatelessWidget {
  const NoBttn({
    super.key,
    required this.noCount,
    required this.onTap,
    required this.text,
  });
  final int noCount;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double shrinkFactor = (1.0 - (noCount * 0.12)).clamp(0.5, 1.0);
    // As the button shrinks, we reduce padding to keep text visible
    double dynamicPadding = (12.0 * shrinkFactor).clamp(4.0, 12.0);

    return CommonButtonBase(
      onTap: onTap,
      color: Colors.redAccent,
      text: text,
      width: (140 * shrinkFactor),
      height: (60 * shrinkFactor),
      fontSize: (16 * shrinkFactor).clamp(12.0, 16.0), // Keep text readable
      padding: dynamicPadding,
    );
  }
}

/// --- BASE BUTTON WITH FITTED TEXT ---
class CommonButtonBase extends StatelessWidget {
  const CommonButtonBase({
    super.key,
    required this.color,
    required this.text,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.padding,
    this.onTap,
  });

  final Color color;
  final String text;
  final double width;
  final double height;
  final double fontSize;
  final double padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(padding), // Dynamic padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: FittedBox(
          fit:
              BoxFit.contain, // Forces text to fit exactly inside button bounds
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
