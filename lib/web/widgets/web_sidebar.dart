import 'package:flutter/material.dart';

class WebSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavItem('Home', Icons.home_filled, true),
          _buildNavItem('Shorts', Icons.play_circle_filled, false),
          _buildNavItem('Iscrizioni', Icons.subscriptions_outlined, false),
          const Divider(color: Colors.grey),
          _buildNavItem('La tua libreria', Icons.video_library_outlined, false),
          _buildNavItem('Cronologia', Icons.history_outlined, false),
          _buildNavItem('I tuoi video', Icons.slideshow_outlined, false),
          _buildNavItem('Guarda più tardi', Icons.watch_later_outlined, false),
          _buildNavItem('Video piaciuti', Icons.thumb_up_outlined, false),
          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Iscrizioni',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.1),
      onTap: () {
        // Gestisci la navigazione qui
      },
      dense: true,
      horizontalTitleGap: 12,
    );
  }
}