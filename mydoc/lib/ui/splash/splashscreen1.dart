import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:in_app_update/in_app_update.dart';
import 'splashscreen.dart' show splashscreen;

class SingleSplashScreen extends StatefulWidget {
  @override
  _SingleSplashScreenState createState() => _SingleSplashScreenState();
}

class _SingleSplashScreenState extends State<SingleSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInOut;
  late Animation<double> _scaleIn;

  bool showTextLogo = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInOut = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    startSequence();
  }

  // Future<void> _checkForUpdate() async {
  //   try {
  //     AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
  //     if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
  //         updateInfo.immediateUpdateAllowed) {
  //       await InAppUpdate.performImmediateUpdate();
  //     }
  //   } catch (e) {
  //     print("Error checking update: $e");
  //   }
  // }

  void startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        showTextLogo = true;
      });
      _controller.forward();
    }

    // _checkForUpdate();

    // Delay thora barha diya taake text read kiya ja saky
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => splashscreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (!showTextLogo)
            Center(
              child: Image.asset(
                "assets/icons/black_notext.png",
                width: 180,
              ),
            ),

          if (showTextLogo)
            Center(
              child: FadeTransition(
                opacity: _fadeInOut,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Center contents
                    children: [
                      Image.asset(
                        "assets/icons/black_new.png",
                        width: 220, // Adjusted for space
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF204F57),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Ambient Clinical Intelligence",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "\nPractice Medicine. Not Paperwork.",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          /// Powered by section
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Powered By",
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  "M3 Hive",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF204F57),
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