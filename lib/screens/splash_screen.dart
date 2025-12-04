import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsü
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0)),
    );

    _controller.forward();

    // Firebase anonim giriş + 3 saniye sonra HomeScreen
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      // Hata olsa bile devam et (offline destek için)
    }

    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, _, _) => const HomeScreen(),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO (assets/images/logo.png varsa)
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Logo yoksa kırmızı daire koy
                      return Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCB312A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_stories, size: 80, color: Colors.white),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 50),

                // MÂNÂ YAZISI
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFCB312A), Color(0xFFFF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Mânâ",
                    style: TextStyle(
                      fontFamily: 'Ahkio',
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 20,
                          color: Color(0xFFCB312A),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // İnce loading çubuğu
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCB312A)),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}