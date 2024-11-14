import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

class TikTokScrollPhysics extends PageScrollPhysics {
  const TikTokScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  TikTokScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TikTokScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 100.0; // Valore leggermente aumentato
  @override
  double get maxFlingVelocity => 2500.0; // Valore leggermente aumentato

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    return ScrollSpringSimulation(
      SpringDescription(
        mass: 10.0, // Ridotto per una simulazione più reattiva
        stiffness: 500.0, // Ridotto per una transizione più morbida
        damping: 20.0, // Aumentato per ridurre le oscillazioni
      ),
      position.pixels,
      velocity > 0 ? position.maxScrollExtent : position.minScrollExtent,
      velocity,
      tolerance: tolerance,
    );
  }

}