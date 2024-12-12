import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

class TikTokScrollPhysics extends PageScrollPhysics {
  const TikTokScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  TikTokScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TikTokScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.5,     // Ridotto per una risposta più veloce
    stiffness: 150, // Ridotto per uno scroll più fluido
    damping: 0.8,   // Ridotto per minor resistenza
  );

  @override
  double get minFlingVelocity => 150.0;  // Aumentato per evitare scroll accidentali
  
  @override
  double get maxFlingVelocity => 2500.0; // Ridotto per maggior controllo
}