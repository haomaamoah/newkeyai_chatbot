import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mainscreens/m.dart';

// Make sure you have a screen to navigate to, e.g., HomeScreen or DashboardScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ⭐️ UPDATED APP TITLE
      title: 'AI Chat Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Using a color that matches the images better
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins', // Optional: A nice modern font
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingContent {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingContent({required this.imagePath, required this.title, required this.description});
}

// ⭐️ UPDATED TITLES AND DESCRIPTIONS FOR YOUR AI CHATBOT APP ⭐️
final List<OnboardingContent> onboardingContents = [
  const OnboardingContent(
    // Make sure to save your first image as 'onboarding1.png' in an 'assets/images/' folder
    imagePath: 'images/queenmother.gif',
    title: 'Welcome to Your\nPersonal AI Assistant',
    description:
        'Get instant answers, creative inspiration, and help with your daily tasks. Your smart companion is here for you 24/7.',
  ),
  const OnboardingContent(
    // Make sure to save your second image as 'onboarding2.png'
    imagePath: 'images/on2.png',
    title: 'Ask Anything,\nGet Answers Instantly',
    description:
        'From solving complex problems to planning your next trip, just start a conversation. No question is too big or too small.',
  ),
  const OnboardingContent(
    // Make sure to save your third image as 'onboarding3.png'
    imagePath: 'images/on3.png',
    title: 'Seamlessly Integrate AI\nInto Your Day',
    description:
        'Boost your productivity and creativity. Let your AI assistant help you write, learn, and brainstorm like never before.',
  ),
];

// The rest of your OnboardingScreen code remains the same.
// I've included it below for completeness with updated theme colors.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _skipToEnd() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    ); // Assuming DashboardScreen exists
  }

  void _nextPage() {
    if (_currentIndex < onboardingContents.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()), // Assuming DashboardScreen exists
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This makes the status bar icons (like time, battery) dark
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip Button
            Positioned(
              top: 10,
              right: 20,
              child: TextButton(
                onPressed: _skipToEnd,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor, // Use theme color
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.only(top: 21),
              child: Column(
                children: [
                  // Image Section
                  Expanded(
                    flex: 5,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: onboardingContents.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [Image.asset(onboardingContents[index].imagePath, height: 310, fit: BoxFit.contain)],
                          ),
                        );
                      },
                    ),
                  ),

                  // Text Content
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            onboardingContents[_currentIndex].title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A237E), // A dark purple/blue
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            onboardingContents[_currentIndex].description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Color(0xFF616161), height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Page Indicators and Button
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingContents.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? Theme.of(context)
                                        .primaryColor // Use theme color
                                  : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor, // Use theme color
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Softer corners
                              elevation: 2,
                            ),
                            child: Text(
                              _currentIndex == onboardingContents.length - 1 ? 'Get Started' : 'Continue',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
