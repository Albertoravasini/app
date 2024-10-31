import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

class TikTokScrollPhysics extends PageScrollPhysics {
  const TikTokScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  TikTokScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TikTokScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 50.0; // Valore ridotto per minFlingVelocity

  @override
  double get maxFlingVelocity => 2000.0; // Puoi regolare questo valore se necessario

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Se non stiamo tentando di scorrere oltre i limiti, usa la simulazione predefinita
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Personalizza la simulazione per rendere lo scroll più veloce
    // Utilizza una curva lineare per accelerare la transizione
    final simulation = ScrollSpringSimulation(
      SpringDescription(
        mass: 30.0, // Aumenta la massa per rendere la simulazione più rapida
        stiffness: 1000.0, // Aumenta la rigidità per una transizione più veloce
        damping: 1.0, // Diminuisci l'ammortizzazione per meno rimbalzi
      ),
      position.pixels,
      velocity > 0 ? position.maxScrollExtent : position.minScrollExtent,
      velocity,
      tolerance: tolerance,
    );

    return simulation;
  }
}