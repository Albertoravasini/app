import 'package:Just_Learn/admin_panel/admin_panel_screen.dart';
import 'package:Just_Learn/main.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class StreakScreen extends StatefulWidget {
  final int consecutiveDays;
  final int coins;
  final VoidCallback onCollectCoins;
  final UserModel userModel; // Aggiunto

  const StreakScreen({
    Key? key,
    required this.consecutiveDays,
    required this.coins,
    required this.onCollectCoins,
    required this.userModel, // Aggiunto
  }) : super(key: key);

  @override
  _StreakScreenState createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> with TickerProviderStateMixin {
  late AnimationController _coinAnimationController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late AudioPlayer _audioPlayer;
  bool _coinsCollected = false;
  int coinsToAdd = 0;  // Variabile di stato per le monete aggiunte

  @override
  void initState() {
    super.initState();
    _coinAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _audioPlayer = AudioPlayer();
    _rotateController.repeat(); // Animazione di rotazione continua
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _collectCoins() async {
    setState(() {
      _coinsCollected = true;
      // Calcola le monete in base ai giorni consecutivi: 10 il primo giorno, poi +5 ogni giorno
      coinsToAdd = 10 + (widget.consecutiveDays - 1) * 5;
    });

    // Avvia l'animazione e il suono
    _coinAnimationController.forward();
    _fadeController.forward();

    try {
      await _audioPlayer.play(AssetSource('success_sound.mp3'));
      print('Audio played successfully'); // Debugging
    } catch (e) {
      print('Error playing audio: $e'); // Debugging
    }

    // Attendi un breve periodo dopo l'animazione
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      print('Updating coins in Firestore with $coinsToAdd coins');

      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.userModel.uid).update({
          'coins': FieldValue.increment(coinsToAdd),
        });
        print('Coins updated in Firestore');
      } catch (e) {
        print('Error updating coins: $e');
      }

      // Naviga alla schermata principale
      if (widget.userModel.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
        );
        print('Navigated to AdminPanelScreen');
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen(userModel: widget.userModel)),
        );
        print('Navigated to MainScreen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center, // Aggiungi questa riga per centrare i figli dello Stack
        children: [
          // Sfondo con gradient dinamico
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.black54],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animazione del titolo Streak
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _coinAnimationController,
                    curve: Curves.elasticOut,
                  ),
                  child: Text(
                    'Streak Master!',
                    style: TextStyle(
                      fontSize: 42,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: Colors.yellowAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // Animazione del messaggio di Streak
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _coinAnimationController,
                    curve: Curves.easeIn,
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'You’ve logged in for ',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        TextSpan(
                          text: '${widget.consecutiveDays}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                          ),
                        ),
                        TextSpan(
                          text: ' consecutive days!',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Animazione per il pulsante di raccolta monete con rotazione
                GestureDetector(
                  onTap: _coinsCollected ? null : _collectCoins,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _rotateController,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.orangeAccent, Colors.redAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.yellowAccent, Colors.orangeAccent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: _coinsCollected
                              ? AnimatedBuilder(
                                  animation: _coinAnimationController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, -150 * _coinAnimationController.value),
                                      child: Opacity(
                                        opacity: 1 - _coinAnimationController.value,
                                        child: Icon(
                                          Icons.stars_rounded,
                                          size: 80,
                                          color: Colors.yellowAccent,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.stars_rounded,
                                  size: 60,
                                  color: Colors.yellowAccent,
                                ),
                        ),
                      ),
                      // Particelle animate per dare più dinamicità
                      if (_coinsCollected) _buildParticleEffect(),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Messaggio di monete raccolte
                AnimatedOpacity(
                  opacity: _coinsCollected ? 1 : 0,
                  duration: const Duration(seconds: 1),
                  child: Text(
                    '+$coinsToAdd Coins Collected!',  // Usa coinsToAdd invece di widget.coins
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Funzione per creare un effetto di particelle quando si raccolgono le monete
  Widget _buildParticleEffect() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _coinAnimationController,
        builder: (context, child) {
          return Stack(
            children: List.generate(15, (index) {
              final random = Random();
              final size = random.nextDouble() * 10 + 5;
              final dx = random.nextDouble() * MediaQuery.of(context).size.width;
              final dy = random.nextDouble() * MediaQuery.of(context).size.height;

              return Positioned(
                left: dx,
                top: dy,
                child: Transform.scale(
                  scale: _coinAnimationController.value,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellowAccent.withOpacity(random.nextDouble()),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}