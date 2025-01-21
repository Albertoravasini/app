import 'package:Just_Learn/models/course.dart';
import 'package:flutter/material.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/web_header.dart';
import '../screens/web_explore_screen.dart';
import '../screens/web_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebMainLayout extends StatefulWidget {
  const WebMainLayout({Key? key}) : super(key: key);

  @override
  State<WebMainLayout> createState() => _WebMainLayoutState();
}

class _WebMainLayoutState extends State<WebMainLayout> {
  int _currentIndex = 0;
  Course? _selectedCourse;
  Section? _selectedSection;
  late final List<Widget> _screens;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      WebHomeScreen(
        key: ValueKey(_selectedCourse?.id),
        selectedCourse: _selectedCourse,
        selectedSection: _selectedSection,
      ),
      ExploreScreen(
        onCourseSelected: _handleCourseSelected,
      ),
    ];
  }

  void _handleCourseSelected(Course course, [Section? section]) {
    setState(() {
      _selectedCourse = course;
      _selectedSection = section;
      _currentIndex = 0; // Torna alla Home
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = _currentIndex == 0 
        ? WebHomeScreen(
            key: ValueKey(_selectedCourse?.id),
            selectedCourse: _selectedCourse,
            selectedSection: _selectedSection,
          )
        : _screens[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        children: [
          WebHeader(
            isAuthenticated: FirebaseAuth.instance.currentUser != null,
            onMenuPressed: () {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            },
          ),
          Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: _isSidebarExpanded ? 240 : 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                  ),
                  child: WebSidebar(
                    currentIndex: _currentIndex,
                    onNavigate: onNavigate,
                    isExpanded: _isSidebarExpanded,
                  ),
                ),
                Expanded(
                  child: currentScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
} 