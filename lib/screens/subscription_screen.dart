import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with TickerProviderStateMixin {
  String selectedPlan = 'annual';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late ScrollController _scrollController;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController = ScrollController()
      ..addListener(() {
        final offset = _scrollController.offset;
        final opacity = (1 - (offset / 100).clamp(0, 1)).toDouble();
        setState(() => _opacity = opacity);
      });
    Posthog().screen(
      screenName: 'Subscription Screen',
      properties: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _incrementClickCount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Incrementa solo il contatore specifico per l'utente
      await _firestore.collection('users').doc(user.uid).set(
        {
          'subscribeClicks': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Premium con design più moderno
          SliverAppBar(
            expandedHeight: 280, // Aumentato per più impatto visivo
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background pattern animato
                  _buildAnimatedBackground(),
                  
                  // Overlay contenuto
                  Opacity(
                    opacity: _opacity,
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Badge Premium più attraente
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.yellowAccent.withOpacity(0.2),
                                  Colors.orangeAccent.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.yellowAccent.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.yellowAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    color: Colors.yellowAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Unlock Your Full\nLearning Potential',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join millions of premium learners',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenuto principale con design migliorato
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Indicatore visivo dello scroll
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 24),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlanSection(),
                        const SizedBox(height: 32),
                        _buildEnhancedFeatures(),
                        const SizedBox(height: 32),
                        _buildEnhancedCTA(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => selectedPlan = 'annual'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  selectedPlan == 'annual'
                      ? Colors.yellowAccent.withOpacity(0.15)
                      : Colors.yellowAccent.withOpacity(0.05),
                  selectedPlan == 'annual'
                      ? Colors.yellowAccent.withOpacity(0.05)
                      : Colors.yellowAccent.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedPlan == 'annual'
                    ? Colors.yellowAccent.withOpacity(0.3)
                    : Colors.yellowAccent.withOpacity(0.1),
                width: selectedPlan == 'annual' ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Annual Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (selectedPlan == 'annual')
                              const Icon(
                                Icons.check_circle,
                                color: Colors.yellowAccent,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.yellowAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SAVE 50%',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '\$29.99',
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'per year',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => selectedPlan = 'monthly'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: selectedPlan == 'monthly'
                  ? const Color(0xFF383838)
                  : const Color(0xFF282828),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedPlan == 'monthly'
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                width: selectedPlan == 'monthly' ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Monthly Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (selectedPlan == 'monthly')
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '\$9.99',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per month',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFeatures() {
    final features = [
      {
        'icon': Icons.star_rounded,
        'title': 'Premium Content',
        'description': 'Access all courses and exclusive materials',
      },
      {
        'icon': Icons.offline_bolt_rounded,
        'title': 'Offline Mode',
        'description': 'Learn anywhere, anytime',
      },
      {
        'icon': Icons.psychology_rounded,
        'title': 'AI Tutor',
        'description': 'Get personalized learning assistance',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: Colors.yellowAccent,
              ),
            ),
            title: Text(
              feature['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              feature['description'] as String,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedCTA() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await _handleSubscribe();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellowAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text(
            'Start Premium Now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cancel anytime. Terms apply.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _handleSubscribe() async {
    await _incrementClickCount();
    
    // Tracciamento migliorato con Posthog
    Posthog().capture(
      eventName: 'subscription_purchase_attempted',
      properties: {
        'plan_type': selectedPlan,
        'price': selectedPlan == 'annual' ? 29.99 : 9.99,
        'currency': 'USD',
        'timestamp': DateTime.now().toIso8601String(),
        'screen': 'subscription_screen',
        'button_clicked': 'start_premium_now'
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The premium version will be available soon!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.yellowAccent.withOpacity(0.1),
            Colors.orangeAccent.withOpacity(0.05),
            Colors.black.withOpacity(0.1),
          ],
        ),
      ),
    );
  }
}