import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CustomProgressBar extends StatelessWidget {
  final YoutubePlayerController controller;
  
  const CustomProgressBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        double progress = value.position.inMilliseconds / 
                         value.metaData.duration.inMilliseconds;
        
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Container(
                height: 3.0,
                color: Colors.grey[800],
              ),
              Container(
                height: 3.0,
                width: MediaQuery.of(context).size.width * (progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0)),
                color: Colors.yellowAccent,
              ),
            ],
          ),
        );
      },
    );
  }
} 