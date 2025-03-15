import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import 'package:Just_Learn/screens/Privacy_Policy_Screen.dart';
import 'package:Just_Learn/screens/Terms_Of_Use_Screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with TickerProviderStateMixin {
  String selectedPlan = 'semiannual';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late ScrollController _scrollController;
  double _opacity = 1.0;
  List<Offering>? _offerings;
  bool _isLoading = true;
  bool _isPressed = false;
  bool _showFloatingCTA = false;
  double _ctaOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController = ScrollController()
      ..addListener(() {
        final offset = _scrollController.offset;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final viewportHeight = _scrollController.position.viewportDimension;
        final scrollPercentage = (offset / maxScroll).clamp(0.0, 1.0);
        
        setState(() {
          if (offset >= maxScroll) {
            _ctaOpacity = 1.0;
          } else if (offset > 300) {
            _ctaOpacity = ((offset - 300) / 100).clamp(0.0, 1.0);
          } else {
            _ctaOpacity = 0.0;
          }
          _showFloatingCTA = offset > 300;
        });
      });
    _loadOfferings();
    Posthog().screen(
      screenName: 'Premium Subscription',
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

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering("premium"); // Usa l'ID dell'offering configurato
      
      print('DEBUG: Offering trovato: ${offering?.identifier}');
      print('DEBUG: Pacchetti disponibili: ${offering?.availablePackages.length}');
      
      setState(() {
        _offerings = offering != null ? [offering] : [];
        _isLoading = false;
      });
    } catch (e) {
      print('Errore nel caricamento delle offerte: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Base background color
          Container(
            color: const Color(0xFF121212),
          ),
          // Subtle top gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E1C00).withOpacity(0.8),
                    const Color(0xFF1A1A00).withOpacity(0.3),
                    const Color(0xFF121212).withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7],
                ),
              ),
            ),
          ),
          // Subtle glow effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.yellowAccent.withOpacity(0.015),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Premium badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.yellowAccent.withOpacity(0.2),
                                    Colors.orangeAccent.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.yellowAccent.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.crown,
                                    color: Colors.yellowAccent,
                                    size: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.yellowAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Main title with gradient
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Colors.white70],
                              ).createShader(bounds),
                              child: const Text(
                                'Sblocca Tutti i Corsi\n e Molto Altro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Impara dai migliori insegnanti',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Plans section first
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Plans section
                      _buildPlanSection(),
                      const SizedBox(height: 32),
                      // Premium features section
                      _buildPremiumFeatures(),
                      const SizedBox(height: 32),
                      // Social proof section
                      _buildSocialProof(),
                      const SizedBox(height: 32),
                      // Policy text and secure payment info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.shield,
                            size: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Disdici quando vuoi · Pagamento sicuro',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'Abbonandoti, accetti i nostri '),
                            TextSpan(
                              text: 'Termini di Utilizzo',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TermsOfUseScreen(),
                                    ),
                                  );
                                },
                            ),
                            const TextSpan(text: ' e la '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyPolicyScreen(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    final features = [
      {
        'icon': FontAwesomeIcons.unlock,
        'title': 'Accesso Illimitato',
        'description': 'Accedi al 100% dei corsi',
      },
      {
        'icon': FontAwesomeIcons.solidMessage,
        'title': 'Chat con i Professori',
        'description': 'Messaggi diretti con tutti gli insegnanti',
      }, 
      {
        'icon': Icons.school,
        'title': 'Compiti e Consulenze Private',
        'description': 'Alla fine di ogni corso consegna il compito e fattelo correggere',
      },
      {
        'icon': FontAwesomeIcons.rocket,
        'title': 'Nuovi Corsi Settimanali',
        'description': 'Contenuti freschi dai migliori insegnanti',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          width: double.infinity,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['description'] as String,
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
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 6-month plan
        _buildPlanCard(
          title: 'Piano 6 Mesi',
          price: '€29.99',
          period: '6 mesi',
          savings: 'RISPARMI 50%',
          isSelected: selectedPlan == 'semiannual',
          onTap: () => setState(() => selectedPlan = 'semiannual'),
        ),
        const SizedBox(height: 12),
        // Monthly plan
        _buildPlanCard(
          title: 'Piano Mensile',
          price: '€9.99',
          period: 'mese',
          isSelected: selectedPlan == 'monthly',
          onTap: () => setState(() => selectedPlan = 'monthly'),
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    String? savings,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return GestureDetector(
      onTap: () async {
        setState(() => selectedPlan = isPrimary ? 'semiannual' : 'monthly');
        await _handleSubscribe();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPrimary ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isSelected 
                  ? Colors.yellowAccent.withOpacity(0.15)
                  : Colors.yellowAccent.withOpacity(0.05),
              isSelected
                  ? Colors.yellowAccent.withOpacity(0.05)
                  : Colors.orangeAccent.withOpacity(0.05),
            ],
          ) : null,
          color: isPrimary ? null : (isSelected ? const Color(0xFF383838) : const Color(0xFF282828)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isPrimary ? Colors.yellowAccent.withOpacity(0.3) : Colors.white.withOpacity(0.2))
                : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isPrimary ? Colors.yellowAccent : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: isPrimary ? Colors.yellowAccent : Colors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      if (savings != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.yellowAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            savings,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: isPrimary ? Colors.yellowAccent : Colors.white,
                        fontSize: isPrimary ? 32 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per $period',
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
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.star, color: Colors.yellowAccent, size: 20),
            )),
          ),
          const SizedBox(height: 12),
          const Text(
            '4.9 su 5',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scelto da più di 1000 studenti',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
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
            const Color(0xFF121212),
          ],
          stops: const [0.0, 0.3, 0.6],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    try {
      setState(() => _isLoading = true);
      
      final offerings = await PurchaseService.getOfferings();
      if (offerings.isEmpty) {
        throw 'Nessuna offerta disponibile';
      }

      final offering = offerings.first;
      final package = PurchaseService.getPackageForPlan(offering, selectedPlan);
      
      if (package == null) {
        throw 'Pacchetto non trovato';
      }

      print('DEBUG: Tentativo di acquisto pacchetto: ${package.identifier}');
      
      // Mostra un indicatore di caricamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final customerInfo = await PurchaseService.purchasePackage(package);
      
      // Chiudi il dialog di caricamento
      Navigator.of(context).pop();
      
      if (PurchaseService.isProUser(customerInfo)) {
        // Traccia l'evento con Posthog
        Posthog().capture(
          eventName: 'subscription_purchased',
          properties: {
            'plan_type': selectedPlan,
            'package_id': package.identifier,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        await _incrementClickCount();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abbonamento attivato con successo!'),
            backgroundColor: Colors.white,
          ),
        );
        
        // Chiudi la schermata di abbonamento
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Chiudi il dialog di caricamento se è aperto
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      
      // Mostra un messaggio di errore appropriato
      String errorMessage = 'Errore durante l\'acquisto';
      if (e.toString().contains('cancellato')) {
        errorMessage = 'Acquisto cancellato';
      } else if (e.toString().contains('non consentiti')) {
        errorMessage = 'Acquisti non consentiti su questo dispositivo';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}