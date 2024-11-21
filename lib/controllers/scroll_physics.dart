import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

class TikTokScrollPhysics extends PageScrollPhysics {
  const TikTokScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  TikTokScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TikTokScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 50.0; // Ridotto per permettere scroll più leggeri
  @override
  double get maxFlingVelocity => 4000.0; // Aumentato per scroll più veloci

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    return ScrollSpringSimulation(
      SpringDescription(
        mass: 0.5, // Ridotto significativamente per una risposta più immediata
        stiffness: 200.0, // Ridotto per uno scroll più morbido
        damping: 1.1, // Ridotto per permettere un movimento più fluido
      ),
      position.pixels,
      velocity > 0 ? position.maxScrollExtent : position.minScrollExtent,
      velocity,
      tolerance: tolerance,
    );
  }

}