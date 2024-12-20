import 'package:flutter/material.dart';

class WebVideoInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Title',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Author Name',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          // Sezione commenti
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Numero di commenti
              itemBuilder: (context, index) {
                return _buildCommentItem();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Name',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Comment text goes here...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
} 