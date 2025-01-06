import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WebSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;

  const WebSidebar({
    Key? key,
    required this.currentIndex,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Sezione principale
          _buildSection([
            _NavItem(
              icon: FontAwesomeIcons.house,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onNavigate(0),
            ),
            _NavItem(
              icon: FontAwesomeIcons.compass,
              label: 'Explore',
              isSelected: currentIndex == 1,
              onTap: () => onNavigate(1),
            ),
            _NavItem(
              icon: FontAwesomeIcons.play,
              label: 'Shorts',
              badge: '9+',
              onTap: () {},
            ),
          ]),

          // Sezione libreria
          _buildSection([
            _buildSectionHeader('Your Library'),
            _NavItem(
              icon: FontAwesomeIcons.book,
              label: 'My Courses',
              onTap: () {},
            ),
            _NavItem(
              icon: FontAwesomeIcons.clock,
              label: 'Watch Later',
              onTap: () {},
            ),
            _NavItem(
              icon: FontAwesomeIcons.heart,
              label: 'Liked',
              onTap: () {},
            ),
            _NavItem(
              icon: FontAwesomeIcons.clockRotateLeft,
              label: 'History',
              onTap: () {},
            ),
          ]),

          // Sezione iscrizioni
          _buildSection([
            _buildSectionHeader('Following'),
            _NavItem(
              icon: FontAwesomeIcons.graduationCap,
              label: 'Top Teachers',
              badge: 'NEW',
              onTap: () {},
            ),
            _NavItem(
              icon: FontAwesomeIcons.users,
              label: 'Communities',
              onTap: () {},
            ),
          ]),

          const Spacer(),

          // Sezione inferiore
          _buildSection([
            _NavItem(
              icon: FontAwesomeIcons.gear,
              label: 'Settings',
              onTap: () {},
            ),
            _NavItem(
              icon: FontAwesomeIcons.circleQuestion,
              label: 'Help Center',
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.grey[400],
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.yellowAccent : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.inter(
                        color: Colors.yellowAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}