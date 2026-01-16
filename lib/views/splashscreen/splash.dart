import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import '../onboard/on.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // --- ⭐️ Colors for AI Chat Assistant Theme ⭐️ ---
  static const Color kBackgroundColor = Color(0xFF1A1A2E); // Very dark purple/blue
  static const Color kPrimaryColor = Color(0xFF7B4BFF);   // Vibrant Purple
  static const Color kAccentColor = Color(0xFF9D7BFF);    // Lighter Lavender/Purple
  static const Color kTextColor = Colors.white;
  static const Color kSecondaryTextColor = Color(0xFFB0B0D0); // Light purple-grey

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);

    _navigateToOnboarding();
  }

  void _navigateToOnboarding() async {
    // Wait for 4 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
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
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundEffect(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [kPrimaryColor, kAccentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    // ⭐️ UPDATED ICON ⭐️
                    child: ClipOval( // Use ClipOval to make the GIF circular within the container
                      child: Image.asset(
                        'images/splash.jpeg', // <-- Your GIF path here
                        height: 150, // Adjust the size as needed
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "NewKey ABUSUA AI", // ⭐️ UPDATED TITLE ⭐️
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your Smart Conversation Companion", // ⭐️ UPDATED TAGLINE ⭐️
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: kSecondaryTextColor,
                  ),
                ),
                const SizedBox(height: 60),
                SpinKitThreeBounce(
                  color: kAccentColor.withValues(alpha:0.8),
                  size: 35.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundEffect() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            kPrimaryColor.withValues(alpha:0.15),
            kBackgroundColor,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}