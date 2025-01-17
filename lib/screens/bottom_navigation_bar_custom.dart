import 'package:flutter/material.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavigationBarCustom extends StatefulWidget {
  final UserModel? currentUser;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigationBarCustom({
    super.key,
    this.currentUser,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  _BottomNavigationBarCustomState createState() => _BottomNavigationBarCustomState();
}

class _BottomNavigationBarCustomState extends State<BottomNavigationBarCustom> {
  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const SizedBox.shrink();
    }

    bool isQuizFree = widget.currentUser!.dailyVideosCompleted >= 
        (3 + (widget.currentUser!.dailyQuizFreeUses * 5));
    bool showQuizDot = isQuizFree && widget.currentUser!.dailyVideosCompleted >= 3;
    bool hasUnreadNotifications = widget.currentUser!.notifications
        .where((notification) => !notification.isRead)
        .isNotEmpty;

    return Container(
      width: double.infinity,
      height: 55 + (MediaQuery.of(context).padding.bottom / 2),
      color: const Color(0xFF121212),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icona Insegnanti - MODIFICATA
          _buildNavItem(
            FontAwesomeIcons.chalkboardUser,
            widget.selectedIndex == 0,
            onTap: () => widget.onItemTapped(0),
          ),

          // Icona Corsi
          _buildNavItem(
            FontAwesomeIcons.graduationCap,
            widget.selectedIndex == 1,
            onTap: () => widget.onItemTapped(1),
            showDot: showQuizDot,
            dotColor: Colors.yellowAccent,
          ),

          // Icona Home
          _buildNavItem(
            FontAwesomeIcons.house,
            widget.selectedIndex == 2,
            onTap: () => widget.onItemTapped(2),
          ),

          // Icona Chat/Notifiche
          _buildNavItem(
            FontAwesomeIcons.solidComments,
            widget.selectedIndex == 3,
            onTap: () => widget.onItemTapped(3),
            showDot: hasUnreadNotifications,
            dotColor: Colors.redAccent,
          ),

          // Icona Profilo
          _buildNavItem(
            FontAwesomeIcons.solidUser,
            widget.selectedIndex == 4,
            onTap: () => widget.onItemTapped(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    bool isSelected, {
    required VoidCallback onTap,
    bool showDot = false,
    Color dotColor = Colors.yellowAccent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: FaIcon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF434348),
              size: 22,
            ),
          ),
          if (showDot)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}