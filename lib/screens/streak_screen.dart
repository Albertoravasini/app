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
  late AnimationController _mainController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _collectController;
  bool _isCollecting = false;
  
  final List<ParticleModel> particles = [];
  final Random random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _collectController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30.0,
      ),
    ]).animate(_collectController);

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _collectController,
      curve: const Interval(0.6, 1.0),
    ));
  }

  void _initializeAnimations() {
    // Controller principale per l'entrata degli elementi
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controller per la rotazione continua
    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Controller per l'effetto pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Controller per le particelle
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Avvia l'animazione principale
    _mainController.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      particles.add(ParticleModel(
        position: Offset(
          random.nextDouble() * 400 - 200,
          random.nextDouble() * 400 - 200,
        ),
        speed: random.nextDouble() * 2 + 1,
        theta: random.nextDouble() * 2 * pi,
        size: random.nextDouble() * 4 + 2,
      ));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _collectController.dispose();
    _mainController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background con effetto aurora
          _buildAuroraEffect(),

          // Particelle animate
          _buildParticleEffect(),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header principale
              SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cerchi concentrici animati
                      ..._buildConcentricCircles(),
                      
                      // Contenuto principale
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildMainContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sezione ricompensa
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _mainController,
                    curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _mainController,
                      curve: Interval(0.4, 1.0),
                    ),
                    child: _buildRewardSection(),
                  ),
                ),
              ),

              // Timeline dei traguardi
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _mainController,
                    curve: Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _mainController,
                      curve: Interval(0.6, 1.0),
                    ),
                    child: _buildMilestonesSection(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuroraEffect() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(
                  0.15,
                  _rotateController.value * 360,
                  0.6,
                  0.2,
                ).toColor(),
                HSLColor.fromAHSL(
                  0.15,
                  (_rotateController.value * 360 + 60) % 360,
                  0.6,
                  0.1,
                ).toColor(),
              ],
              transform: GradientRotation(_rotateController.value * 2 * pi),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildConcentricCircles() {
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          double scale = 1.0 + (_pulseController.value * 0.1);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 200 + (index * 50).toDouble(),
              height: 200 + (index * 50).toDouble(),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.yellowAccent.withOpacity(0.1 - (index * 0.03)),
                  width: 1,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge animato
        _buildAnimatedBadge(),
        
        SizedBox(height: 32),
        
        // Counter principale
        _buildStreakCounter(),
        
        SizedBox(height: 32),
        
        // Statistiche
        _buildStats(),
      ],
    );
  }

  Widget _buildAnimatedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.yellowAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.yellowAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.yellowAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icona con effetto glow
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.yellowAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.yellowAccent,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          // Testo con stile coerente
          Text(
            'Top 10% of users',
            style: TextStyle(
              color: Colors.yellowAccent.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCounter() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anello di progresso animato
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.consecutiveDays / 30),
          duration: Duration(seconds: 2),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return CustomPaint(
              size: Size(200, 200),
              painter: ProgressRingPainter(
                progress: value,
                color: Colors.yellowAccent,
                strokeWidth: 8,
              ),
            );
          },
        ),

        // Counter centrale
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0xFF282828),
                Color(0xFF1E1E1E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.yellowAccent.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.yellowAccent,
                size: 40,
              ),
              SizedBox(height: 8),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: widget.consecutiveDays),
                duration: Duration(seconds: 2),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'gg',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Text(
                'STREAK',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticleEffect() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        for (var particle in particles) {
          particle.position = Offset(
            particle.position.dx + cos(particle.theta) * particle.speed,
            particle.position.dy + sin(particle.theta) * particle.speed,
          );

          if (particle.position.dx < -200) particle.position = Offset(200, particle.position.dy);
          if (particle.position.dx > 200) particle.position = Offset(-200, particle.position.dy);
          if (particle.position.dy < -200) particle.position = Offset(particle.position.dx, 200);
          if (particle.position.dy > 200) particle.position = Offset(particle.position.dx, -200);
        }

        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(particles: particles),
        );
      },
    );
  }

  Widget _buildRewardSection() {
    // Calcolo base dei coins giornalieri
    final baseCoins = 10 + (widget.consecutiveDays - 1) * 5;
    
    // Calcolo bonus per i traguardi
    int bonusCoins = 0;
    if (widget.consecutiveDays == 7) {
      bonusCoins = 100;
    } else if (widget.consecutiveDays == 14) {
      bonusCoins = 250;
    } else if (widget.consecutiveDays == 30) {
      bonusCoins = 500;
    }

    // Totale coins da aggiungere
    final totalCoins = baseCoins + bonusCoins;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.yellowAccent.withOpacity(0.15),
                Colors.orangeAccent.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.yellowAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.yellowAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+$totalCoins coins',
                          style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (bonusCoins > 0)
                          Text(
                            'Includes milestone bonus: +$bonusCoins',
                            style: TextStyle(
                              color: Colors.yellowAccent.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        Text(
                          'Streak bonus x${widget.consecutiveDays}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _collectController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isCollecting ? _scaleAnimation.value : 1.0,
                    child: FadeTransition(
                      opacity: _isCollecting ? _fadeAnimation : const AlwaysStoppedAnimation(1.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isCollecting ? null : () async {
                            setState(() => _isCollecting = true);
                            
                            await _audioPlayer.play(AssetSource('Coins ClinkCollect SFX 25 Sounds (1).mp3'));
                            
                            await _collectController.forward();

                            if (mounted) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.userModel.uid)
                                    .update({
                                  'coins': FieldValue.increment(totalCoins),
                                });

                                if (widget.userModel.role == 'admin') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const AdminPanelScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => MainScreen(
                                        userModel: widget.userModel,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Errore aggiornamento coins: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.celebration_rounded, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Collect',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (_isCollecting)
          AnimatedBuilder(
            animation: _collectController,
            builder: (context, child) {
              return Positioned.fill(
                child: _buildCollectAnimation(totalCoins),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCollectAnimation(int coins) {
    return Stack(
      children: List.generate(10, (index) {
        final random = Random();
        final startAlignment = Alignment(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        );
        
        return TweenAnimationBuilder<Alignment>(
          tween: AlignmentTween(
            begin: startAlignment,
            end: const Alignment(0, -1),
          ),
          duration: Duration(milliseconds: 800 + random.nextInt(400)),
          builder: (context, alignment, child) {
            return Align(
              alignment: alignment,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Text(
                    '+$coins',
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

Widget _buildMilestonesSection() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Next Milestones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.yellowAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.yellowAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildMilestoneRow(
                days: 7,
                coins: 100,
                progress: widget.consecutiveDays / 7,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: Color(0xFF282828),
                  height: 1,
                ),
              ),
              _buildMilestoneRow(
                days: 14,
                coins: 250,
                progress: widget.consecutiveDays / 14,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: Color(0xFF282828),
                  height: 1,
                ),
              ),
              _buildMilestoneRow(
                days: 30,
                coins: 500,
                progress: widget.consecutiveDays / 30,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

Widget _buildMilestoneRow({
  required int days,
  required int coins,
  required double progress,
}) {
  final double actualProgress = (widget.consecutiveDays / days).clamp(0.0, 1.0);
  final bool isCompleted = widget.consecutiveDays >= days;
  final bool isActive = !isCompleted;
  final int daysLeft = days - widget.consecutiveDays;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Giorni e stato
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.yellowAccent.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted 
                        ? Colors.yellowAccent.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.local_fire_department_rounded,
                  color: isCompleted ? Colors.yellowAccent : Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$days days',
                style: TextStyle(
                  color: isCompleted ? Colors.yellowAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Coins reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: Colors.yellowAccent.withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '+$coins',
                  style: TextStyle(
                    color: Colors.yellowAccent.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // Progress bar aggiornata
      Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 4,
                        width: constraints.maxWidth * actualProgress,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.yellowAccent : Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (isActive && daysLeft > 0) ...[
            const SizedBox(width: 12),
            Text(
              '$daysLeft days',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

  Widget _buildStats() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem('Best Streak', '15 days', Icons.emoji_events_rounded),
          Container(
            height: 24,
            width: 1,
            margin: EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withOpacity(0.1),
          ),
          _buildStatItem('Total Coins', '${widget.coins}', Icons.monetization_on_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.yellowAccent, size: 16),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ... [resto del codice esistente] ...
}

// Custom Painter per l'anello di progresso
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Disegna il background
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(0.1)
        ..strokeWidth = strokeWidth,
    );

    // Disegna il progresso
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// Modello per le particelle
class ParticleModel {
  Offset position;
  double speed;
  double theta;
  double size;

  ParticleModel({
    required this.position,
    required this.speed,
    required this.theta,
    required this.size,
  });
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellowAccent.withOpacity(0.2);
    for (var particle in particles) {
      canvas.drawCircle(
        Offset(
          size.width / 2 + particle.position.dx,
          size.height / 2 + particle.position.dy,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}