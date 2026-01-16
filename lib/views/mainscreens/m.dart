import 'package:flutter/foundation.dart'; // Import kIsWeb for platform detection
import 'package:flutter/material.dart';
import '../askanything/as.dart';

// 1. CONVERTED TO A STATEFUL WIDGET to manage the selected item
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 2. STATE VARIABLE to hold the currently selected feature
  DashboardItem? _selectedFeature;

  // Moved feature list and gradients inside the State for better organization
  late final List<DashboardItem> features;
  late final List<Gradient> gradients;

  @override
  void initState() {
    super.initState();
    features = [
      DashboardItem(
        "images/queenmother.gif",
        '👑 Yaa —Assisant',
        const ChatAIScreen(),
      ),
      DashboardItem(
        "images/realtor.gif",
        '🏠 Kwame — Realtor',
        const ChatAIScreen(),
      ),
      DashboardItem(
        "images/secretary.gif",
        '📅 Abena — Secretary',
        const ChatAIScreen(),
      ),
      DashboardItem(
        "images/doctor.gif",
        '🩺 Kofi — Doctor',
        const ChatAIScreen(),
      ),
      DashboardItem(
        "images/courier.gif",
        '🚚 Yaw — Courier',
        const ChatAIScreen(),
      ),
    ];

    gradients = [
      const LinearGradient(colors: [Color(0xFF4A6CF7), Color(0xFF9F7AEA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ];

    // On web/large screens, select the first feature by default to avoid an empty right side.
    if (kIsWeb) {
      _selectedFeature = features.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // A screen is considered "large" if it's running on web or if its width is over a certain threshold.
    final bool isLargeScreen = kIsWeb || MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ABUSUA AI Chatbots',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF4A6CF7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      // 3. RENDER DIFFERENT LAYOUTS based on screen size
      body: isLargeScreen ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  /// Builds the standard GridView layout for mobile devices.
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: _buildGridView(), // Re-uses the common GridView widget
    );
  }

  /// Builds the split-screen (Master-Detail) layout for web and large screens.
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left "Master" side: The GridView, constrained in width.
        SizedBox(
          width: 320, // A fixed width for the navigation list on the left
          child: _buildGridView(),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // Right "Detail" side: The expanded view that shows the content.
        Expanded(
          child: _selectedFeature != null
              ? _buildDetailView(_selectedFeature!)
              : const Center(child: Text("Select an agent to start chatting")), // Fallback message
        ),
      ],
    );
  }

  /// The Detail View widget that shows the selected feature's screen.
  Widget _buildDetailView(DashboardItem item) {
    // This directly embeds the screen (e.g., ChatAIScreen) of the selected item.
    return Container(
      color: Colors.white,
      child: item.screen,
    );
  }

  /// The common GridView widget, now configurable for both layouts.
  Widget _buildGridView() {
    final bool isLargeScreen = kIsWeb || MediaQuery.of(context).size.width > 800;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // On large screens, use a single column list. On mobile, a 2-column grid.
        crossAxisCount: isLargeScreen ? 1 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Adjust aspect ratio for a better look in a single column list
        childAspectRatio: isLargeScreen ? 3.0 : 0.8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        final gradient = gradients[index % gradients.length];
        // Highlight the item if it's selected on a large screen
        final isSelected = _selectedFeature == feature && isLargeScreen;

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          // 4. ONTAP LOGIC based on screen size
          onTap: () {
            if (isLargeScreen) {
              // On web/large screens, update the state to show the detail view
              setState(() {
                _selectedFeature = feature;
              });
            } else {
              // On mobile, navigate to a new screen as before
              Navigator.push(context, MaterialPageRoute(builder: (_) => feature.screen));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              // Add a border to visually indicate the selected item
              border: isSelected ? Border.all(color: const Color(0xFF4A6CF7), width: 3) : null,
              // FIX: Replaced `.withValues` with `.withOpacity`
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            // Use a Row layout for list items on large screens for better readability
            child: isLargeScreen ? _buildRowItemLayout(feature) : _buildColumnItemLayout(feature),
          ),
        );
      },
    );
  }

  // Original item layout for the 2-column mobile grid
  Widget _buildColumnItemLayout(DashboardItem feature) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            // FIX: Replaced `.withValues` with `.withOpacity`
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                feature.assetPath,
                width: 120,
                height: 120,
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feature.name,
            // FIX: Changed color to white for better contrast on gradient
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, height: 1.3),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // New item layout using a Row, perfect for a single-column list on web
  Widget _buildRowItemLayout(DashboardItem feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          ClipOval(child: Image.asset(feature.assetPath, width: 60, height: 120, fit: BoxFit.fitHeight)),
          const SizedBox(width: 30),
          Expanded(
            child: Text(
              feature.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
        ],
      ),
    );
  }
}

class DashboardItem {
  final String assetPath;
  final String name;
  final Widget screen;

  DashboardItem(this.assetPath, this.name, this.screen);
}
