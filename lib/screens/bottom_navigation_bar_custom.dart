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
      height: 60 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121212),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icona Insegnanti
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
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FaIcon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF434348),
              size: 20,
            ),
            if (showDot)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}