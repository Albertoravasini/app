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

    // Determina se mostrare il pallino basato sui video completati
    bool showDot = widget.currentUser!.dailyVideosCompleted >= 3;

    return Container(
      width: double.infinity,
      height: 55,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icona per la schermata corsi
          GestureDetector(
            onTap: () => widget.onItemTapped(0),
            child: _buildNavItem(
              'assets/fluent_hat-graduation-sparkle-24-filled.svg',  // Icona Corsi
              widget.selectedIndex == 0,
            ),
          ),
          const SizedBox(width: 59),  // Spaziatura tra le icone

          // Icona per la schermata Home
          GestureDetector(
            onTap: () => widget.onItemTapped(1),
            child: _buildNavItem(
              'assets/ph_castle-turret-fill.svg',  // Icona Home
              widget.selectedIndex == 1,
            ),
          ),
          const SizedBox(width: 59),  // Spaziatura tra le icone

          // Icona per la schermata Quiz con pallino
          GestureDetector(
            onTap: () => widget.onItemTapped(2),  // Schermata Quiz
            child: Stack(
              children: [
                _buildNavItem(
                  'assets/ic_round-quiz.svg',  // Icona per la schermata Quiz (puoi cambiare l'icona)
                  widget.selectedIndex == 2,
                ),
                if (showDot)
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
          const SizedBox(width: 59),  // Spaziatura tra le icone

          // Icona per la schermata Impostazioni
          GestureDetector(
            onTap: () => widget.onItemTapped(3),  // Schermata Impostazioni
            child: _buildNavItem(
              'assets/iconamoon_profile-fill.svg',  // Icona Impostazioni
              widget.selectedIndex == 3,
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