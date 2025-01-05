import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'web_home_screen.dart';
import '../widgets/web_header.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WebLandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111111),
      body: SingleChildScrollView(
        child: Column(
          children: [
            WebHeader(),
            
            // Hero Section
            _buildHeroSection(),
            
            // Trusted By Section
            _buildTrustedBySection(),
            
            // Stats Section
            _buildStatsSection(),
            
            // For Teachers Section
            _buildTeachersSection(),
            
            // For Students Section
            _buildStudentsSection(),
            
            // Pricing Section
            _buildPricingSection(),
            
            // Features Grid
           
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 900,
      padding: EdgeInsets.symmetric(horizontal: 160),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color(0xFF0A0A0A),
            Color(0xFF111111),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Elementi di sfondo migliorati
          Positioned(
            right: -200,
            top: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.yellowAccent.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          // Mesh gradient blur effect
          Positioned(
            left: -100,
            bottom: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              // Contenuto sinistro migliorato
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge in alto
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.yellowAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Learn While Scrolling',
                            style: GoogleFonts.inter(
                              color: Colors.yellowAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Titolo principale modificato con un solo colore
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'TikTok for Learning\n',
                            style: GoogleFonts.poppins(
                              fontSize: 76,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: 'but Better',
                            style: GoogleFonts.poppins(
                              fontSize: 76,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Sottotitolo migliorato
                    Text(
                      'Create engaging courses, build your community\nand monetize your knowledge in an innovative way.',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: Colors.grey[300],
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 48),
                    
                    // CTA Buttons principali
                    Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellowAccent,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Start Teaching',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[700]!),
                              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Start Learning',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Separatore con testo - versione migliorata
                    Container(
                      width: 505, // Larghezza contenuta che si allinea meglio con il testo sopra
                      margin: EdgeInsets.symmetric(vertical: 32),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Importante per contenere la larghezza
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[800],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Mobile & Web Version',
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500, // Leggermente più bold per leggibilità
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[800],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // App Store Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: () {
                          // Aggiungi qui la logica per aprire l'App Store
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'appstore.png',
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Social proof
                    SizedBox(height: 48),
                    Row(
                      children: [
                        _buildSocialProofItem('4.9/5', 'Average Rating'),
                        SizedBox(width: 48),
                        _buildSocialProofItem('10K+', 'Active Teachers'),
                        SizedBox(width: 48),
                        _buildSocialProofItem('1M+', 'Students'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Contenuto destro (preview app)
              Expanded(
                flex: 4,
                child: Container(
                  height: 700,
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Telefono posteriore
                      Positioned(
                        right: 10,
                        top: 20,
                        child: Container(
                          width: 325,
                          height: 650,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'SimulatorHomeQuestion.png', // Immagine diversa per il secondo telefono
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      
                      // Telefono principale in primo piano
                      Center(
                        child: Container(
                          width: 340,
                          height: 700,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellowAccent.withOpacity(0.1),
                                blurRadius: 50,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'SimulatorHome1.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      
                      // Floating cards con posizioni aggiustate
                      Positioned(
                        top: 80,
                        right: -50,
                        child: _buildFloatingCard(
                          icon: Icons.question_answer,
                          title: 'Answer Questions',
                          color: Colors.green[400]!,
                        ),
                      ),
                      Positioned(
                        top: 240,
                        left: 40,
                        child: _buildFloatingCard(
                          icon: Icons.swipe_up,
                          title: 'Scroll and Learn',
                          color: Colors.blue[400]!,
                        ),
                      ),
                      Positioned(
                        bottom: 240,
                        right: -50,
                        child: _buildFloatingCard(
                          icon: Icons.smart_toy,
                          title: 'AI Powered',
                          color: Colors.purple[400]!,
                        ),
                      ),
                      Positioned(
                        bottom: 80,
                        left: 30,
                        child: _buildFloatingCard(
                          icon: Icons.trending_up,
                          title: 'Track Progress',
                          color: Colors.orange[400]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustedBySection() {
    final List<String> companyLogos = [
      'farm.png',
      'farm.png','farm.png','farm.png','farm.png','farm.png','farm.png','farm.png','farm.png',
      // Aggiungi altri loghi secondo necessità
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 60),
      color: Color(0xFF111111),
      child: Column(
        children: [
          Text(
            'Trusted By',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...companyLogos.map((logo) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Image.asset(
                    logo,
                    height: 40,
                    color: Colors.grey[700], // Rende i loghi monocromatici
                    fit: BoxFit.contain,
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: 120),
      color: Color(0xFF111111),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('1M+', 'Active Students'),
          _buildDivider(),
          _buildStatItem('10K+', 'Expert Teachers'),
          _buildDivider(),
          _buildStatItem('5K+', 'Interactive Courses'),
          _buildDivider(),
          _buildStatItem('95%', 'Success Rate'),
        ],
      ),
    );
  }

  Widget _buildTeachersSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 120, horizontal: 120),
      child: Row(
        children: [
          // Contenuto testuale
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For Teachers',
                  style: GoogleFonts.poppins(
                    color: Colors.yellowAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Transform Your Teaching\nInto a Profitable Business',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Join thousands of teachers earning 5,000+ monthly',
                  style: GoogleFonts.inter(
                    color: Colors.yellowAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 32),
                _buildFeatureList([
                  {
                    'icon': FontAwesomeIcons.play,
                    'text': 'Create engaging courses and attract more students with short-form videos',
                  },
                  {
                    'icon': FontAwesomeIcons.peopleGroup,
                    'text': 'Build lasting relationships with your students through live sessions, chat and events',
                  },
                  {
                    'icon': FontAwesomeIcons.chartLine,
                    'text': 'Track student progress and engagement with advanced analytics',
                  },
                  {
                    'icon': FontAwesomeIcons.crown,
                    'text': 'Offer premium 1:1 coaching and intensive learning periods',
                  },
                  {
                    'icon': FontAwesomeIcons.moneyBillTrendUp,
                    'text': 'Earn from every course with our teacher-friendly revenue share',
                  },
                ]),
                SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Creating',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Nuova sezione dei cellulari
          Expanded(
            flex: 4,
            child: Container(
              height: 700,
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Telefono posteriore
                  Positioned(
                    right: 10,
                    top: 20,
                    child: Container(
                      width: 325,
                      height: 650,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'TeacherCourse.png', // Immagine della dashboard docente
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  // Telefono principale in primo piano
                  Center(
                    child: Container(
                      width: 340,
                      height: 700,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellowAccent.withOpacity(0.1),
                            blurRadius: 50,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'Teacherhome.png', // Immagine dell'app docente
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  // Floating cards specifiche per i docenti
                  Positioned(
                    top: 80,
                    right: -50,
                    child: _buildFloatingCard(
                      icon: Icons.bar_chart,
                      title: 'Analytics Dashboard',
                      color: Colors.blue[400]!,
                    ),
                  ),
                  Positioned(
                    top: 240,
                    left: 40,
                    child: _buildFloatingCard(
                      icon: Icons.people,
                      title: '500+ Students',
                      color: Colors.green[400]!,
                    ),
                  ),
                  Positioned(
                    bottom: 240,
                    right: -50,
                    child: _buildFloatingCard(
                      icon: Icons.payments,
                      title: '500 Earnings',
                      color: Colors.orange[400]!,
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 30,
                    child: _buildFloatingCard(
                      icon: Icons.star,
                      title: '4.9 Rating',
                      color: Colors.purple[400]!,
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

  Widget _buildStudentsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 120, horizontal: 120),
      child: Row(
        children: [
          // Demo App Preview (a sinistra)
          Expanded(
            flex: 6,
            child: Container(
              height: 700,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Telefono sinistro
                  Positioned(
                    left: 0,
                    top: 50,
                    child: Container(
                      width: 300,
                      height: 600,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'SimulatorHomeQuestion.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  // Telefono destro
                  Positioned(
                    right: 0,
                    top: 50,
                    child: Container(
                      width: 300,
                      height: 600,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'SimulatorHome1.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Telefono principale in primo piano
                  Center(
                    child: Container(
                      width: 340,
                      height: 700,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellowAccent.withOpacity(0.1),
                            blurRadius: 50,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'Lesson.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Floating cards
                  Positioned(
                    top: 100,
                    right: 40,
                    child: _buildFloatingCard(
                      icon: Icons.emoji_events,
                      title: 'Daily Streak: 7 Days',
                      color: Colors.amber,
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 40,
                    child: _buildFloatingCard(
                      icon: Icons.workspace_premium,
                      title: 'Level Up!',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content (allineato a destra)
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'For Students',
                  style: GoogleFonts.poppins(
                    color: Colors.yellowAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Learning Will Not Be Boring Anymore',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 32),
                Container(
                  constraints: BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStudentFeature(
                        FontAwesomeIcons.scroll,
                        'Scroll & Learn: Forget the long courses',
                      ),
                      _buildStudentFeature(
                        FontAwesomeIcons.faceLaugh,
                        'Engaging short-form videos that keep you hooked while learning',
                      ),
                      _buildStudentFeature(
                        FontAwesomeIcons.question,
                        'Interactive quizzes while you scroll',
                      ),
                      _buildStudentFeature(
                        FontAwesomeIcons.userGraduate,
                        'Personal mentorship from expert teachers',
                      ),
                      _buildStudentFeature(
                        FontAwesomeIcons.trophy,
                        'Gamified learning with rewards and achievements',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Learning',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 18,
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

  Widget _buildPricingSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 120, horizontal: 160),
      child: Column(
        children: [
          // Header della sezione
          Text(
            'Pricing Plans',
            style: GoogleFonts.poppins(
              color: Colors.yellowAccent,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Choose Your Learning Journey',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Start with our free plan or upgrade for premium features',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 18,
            ),
          ),
          SizedBox(height: 64),

          // Cards dei piani
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Piano Free
              _buildPricingCard(
                title: 'Free',
                price: '0',
                features: [
                  'Access to basic courses',
                  'Limited video content',
                  'Community access',
                  'Basic progress tracking',
                  'Mobile app access',
                ],
                isPopular: false,
                buttonText: 'Get Started',
                gradientColors: [
                  Colors.grey[800]!,
                  Colors.grey[900]!,
                ],
              ),
              SizedBox(width: 32),

              // Piano Premium (Annuale)
              _buildPricingCard(
                title: 'Premium Annual',
                price: '29.99',
                period: 'year',
                features: [
                  'Unlimited course access',
                  'Premium video content',
                  'AI-powered tutoring',
                  'Advanced analytics',
                  'Offline mode',
                  'Priority support',
                ],
                isPopular: true,
                buttonText: 'Save 50%',
                gradientColors: [
                  Colors.yellowAccent.withOpacity(0.15),
                  Colors.orangeAccent.withOpacity(0.15),
                ],
                showSaveBadge: true,
              ),
              SizedBox(width: 32),

              // Piano Premium (Mensile)
              _buildPricingCard(
                title: 'Premium Monthly',
                price: '9.99',
                period: 'month',
                features: [
                  'Unlimited course access',
                  'Premium video content',
                  'AI-powered tutoring',
                  'Advanced analytics',
                  'Offline mode',
                  'Priority support',
                ],
                isPopular: false,
                buttonText: 'Start Premium',
                gradientColors: [
                  Colors.grey[800]!,
                  Colors.grey[900]!,
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    String period = '',
    required List<String> features,
    required bool isPopular,
    required String buttonText,
    required List<Color> gradientColors,
    bool showSaveBadge = false,
  }) {
    return Container(
      width: 380,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? Colors.yellowAccent.withOpacity(0.3) : Colors.grey[800]!,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Piano e prezzo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showSaveBadge) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SAVE 50%',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$',
                        style: GoogleFonts.poppins(
                          color: isPopular ? Colors.yellowAccent : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        price,
                        style: GoogleFonts.poppins(
                          color: isPopular ? Colors.yellowAccent : Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (period.isNotEmpty)
                    Text(
                      'per $period',
                      style: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 40),

          // Features
          ...features.map((feature) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: isPopular ? Colors.yellowAccent : Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  feature,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )),
          SizedBox(height: 40),

          // CTA Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? Colors.yellowAccent : Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 24),
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'New Achievement',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 64,
      width: 1,
      color: Colors.grey[800],
    );
  }

  Widget _buildFeatureList(List<Map<String, dynamic>> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.yellowAccent.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: Colors.yellowAccent,
                size: 24,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                feature['text'] as String,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // Nuovo widget per social proof
  Widget _buildSocialProofItem(String value, String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.yellowAccent, Colors.yellow[600]!],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Aggiungi questo metodo per costruire le features
  Widget _buildStudentFeature(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(width: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellowAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.yellowAccent.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.yellowAccent,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
} 