import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Just_Learn/models/user.dart';

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

    // Controlla se ci sono notifiche non lette
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
          // Icona Corsi
          GestureDetector(
            onTap: () => widget.onItemTapped(0),
            child: _buildNavItem(
              'assets/fluent_hat-graduation-sparkle-24-filled.svg',
              widget.selectedIndex == 0,
            ),
          ),

          // Icona Quiz
          GestureDetector(
            onTap: () => widget.onItemTapped(1),
            child: Stack(
              children: [
                _buildNavItem(
                  'assets/ic_round-quiz.svg',
                  widget.selectedIndex == 1,
                ),
                if (showQuizDot)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.yellowAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Icona Home (centro)
          GestureDetector(
            onTap: () => widget.onItemTapped(2),
            child: _buildNavItem(
              'assets/ph_castle-turret-fill.svg',
              widget.selectedIndex == 2,
            ),
          ),

          // Icona Messaggi
          GestureDetector(
            onTap: () => widget.onItemTapped(3),
            child: Stack(
              children: [
                _buildNavItem(
                  'assets/ic_round-quiz.svg', // Assicurati di avere questa icona
                  widget.selectedIndex == 3,
                ),
                if (hasUnreadNotifications)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Icona Profilo
          GestureDetector(
            onTap: () => widget.onItemTapped(4),
            child: _buildNavItem(
              'assets/iconamoon_profile-fill.svg',
              widget.selectedIndex == 4,
            ),
          ),
        ],
      ),
    );
  }

  // Metodo per costruire un elemento della barra di navigazione
  Widget _buildNavItem(String assetPath, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          assetPath,
          color: isSelected ? Colors.white : const Color(0xFF434348),
        ),
      ],
    );
  }
}