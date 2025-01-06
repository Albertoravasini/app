import 'package:flutter/material.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/web_header.dart';
import '../screens/web_explore_screen.dart';
import '../screens/web_home_screen.dart';

class WebMainLayout extends StatefulWidget {
  const WebMainLayout({Key? key}) : super(key: key);

  @override
  State<WebMainLayout> createState() => _WebMainLayoutState();
}

class _WebMainLayoutState extends State<WebMainLayout> {
  int _currentIndex = 0;

  // Lista delle schermate disponibili
  final List<Widget> _screens = [
    WebHomeScreen(),
    ExploreScreen(),
  ];

  void onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Header fisso in alto
          WebHeader(),
          
          // Contenuto principale con sidebar
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: WebSidebar(
                    currentIndex: _currentIndex,
                    onNavigate: onNavigate,
                  ),
                ),

                // Contenuto principale scrollabile
                Expanded(
                  child: _screens[_currentIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 