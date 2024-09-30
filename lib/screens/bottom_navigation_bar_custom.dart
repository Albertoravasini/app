import 'package:Just_Learn/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  // ignore: library_private_types_in_public_api
  _BottomNavigationBarCustomState createState() => _BottomNavigationBarCustomState();
}

class _BottomNavigationBarCustomState extends State<BottomNavigationBarCustom> {
  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const SizedBox.shrink();
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = 345.0;
    double horizontalMargin = (screenWidth - containerWidth) / 2;

    return Container(
      width: containerWidth,
      height: 55,
      margin: EdgeInsets.only(bottom: 20, left: horizontalMargin, right: horizontalMargin),
      padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 25),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Colors.white),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Primo pulsante (Home)
          GestureDetector(
            onTap: () => widget.onItemTapped(0),  // Usa il callback qui
            child: SizedBox(
              width: 59,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/ph_castle-turret-fill.svg', // Icona custom per Home
                    color: widget.selectedIndex == 0 ? Colors.black : Colors.black,
                  ),
                  const SizedBox(height: 3),
                  if (widget.selectedIndex == 0)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const ShapeDecoration(
                        color: Colors.black,
                        shape: OvalBorder(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(width: 59), // Spaziatura tra i pulsanti

          // Secondo pulsante (centrale con design personalizzato)
          GestureDetector(
            onTap: () => widget.onItemTapped(1),  // Usa il callback qui
            child: Container(
              width: 59,
              height: 39,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
              decoration: ShapeDecoration(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Colors.white),
                  borderRadius: BorderRadius.circular(13),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Container(width: 59), // Spaziatura tra i pulsanti

          // Terzo pulsante (Settings)
          GestureDetector(
            onTap: () => widget.onItemTapped(2),  // Usa il callback qui
            child: SizedBox(
              width: 59,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/iconamoon_profile-bold.svg', // Icona custom per Settings
                    color: widget.selectedIndex == 2 ? Colors.black : Colors.black,
                  ),
                  const SizedBox(height: 3),
                  if (widget.selectedIndex == 2)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const ShapeDecoration(
                        color: Colors.black,
                        shape: OvalBorder(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}