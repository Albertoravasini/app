import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebOnboardingScreen extends StatefulWidget {
  @override
  _WebOnboardingScreenState createState() => _WebOnboardingScreenState();
}

class _WebOnboardingScreenState extends State<WebOnboardingScreen> {
  int currentStep = 1;
  final int totalSteps = 9;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111111),
      body: Column(
        children: [
          // Header con progress
          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (currentStep > 1) {
                      setState(() => currentStep--);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    'Step $currentStep/$totalSteps',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),

          // Progress bar
          LinearProgressIndicator(
            value: currentStep / totalSteps,
            backgroundColor: Color(0xFF242424),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
          ),

          // Contenuto principale
          Expanded(
            child: Center(
              child: Container(
                width: 480,
                padding: EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getStepTitle(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      _getStepDescription(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 40),
                    _buildStepContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (currentStep) {
      case 1:
        return 'Che obiettivo professionale vuoi raggiungere?';
      case 2:
        return 'Quali di questi argomenti ti interessano di più? 💡';
      case 3:
        return 'Come ti identifichi professionalmente?';
      case 4:
        return 'Che ruolo hai in azienda?';
      case 5:
        return 'Quanto è grande la tua azienda o quella in cui lavori?';
      case 6:
        return 'Hai mai seguito corsi online?';
      case 7:
        return 'Imposta un reminder';
      case 8:
        return 'Dove ci hai scoperto?';
      default:
        return '';
    }
  }

  String _getStepDescription() {
    switch (currentStep) {
      case 1:
        return 'Scegli il tuo obiettivo attuale per permetterci di aiutarti a raggiungerlo.';
      case 2:
        return 'Scegli almeno 3 argomenti. In questo modo sapremo che corsi consigliarti.';
      case 3:
        return 'Questo ci serve per consigliarti il tuo percorso. Potrai sempre cambiarla successivamente.';
      case 4:
        return 'La risposta ci aiuterà a suggerirti i corsi più adatti a te.';
      case 5:
        return 'La risposta ci aiuta a prioritizzare nuove feature e corsi per team.';
      case 6:
        return 'Questo ci serve per capire come guidarti nella piattaforma.';
      case 7:
        return 'L\'84% delle persone che hanno impostato il reminder, hanno creato un\'abitudine di apprendimento e ottenuto più risultati.';
      case 8:
        return 'La risposta ci aiuta a capire dove continuare a investire tempo.';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 1:
        return Column(
          children: [
            _buildOptionButton('👔 Trovare lavoro'),
            SizedBox(height: 16),
            _buildOptionButton('📈 Fare carriera'),
            SizedBox(height: 16),
            _buildOptionButton('💡 Lanciare idea'),
            SizedBox(height: 16),
            _buildOptionButton('🚀 Far crescere azienda'),
            SizedBox(height: 16),
            _buildOptionButton('📚 Sviluppare competenze'),
            SizedBox(height: 16),
            _buildOptionButton('⚡ Altro'),
          ],
        );
      case 2:
        return _buildTopicsGrid();
      case 3:
        return _buildProfessionalIdentity();
      case 4:
        return _buildCompanyRole();
      case 5:
        return _buildCompanySize();
      case 6:
        return _buildOnlineCourseExperience();
      case 7:
        return _buildReminderSettings();
      case 8:
        return _buildDiscoverySource();
      default:
        return Container();
    }
  }

  Widget _buildTopicsGrid() {
    final topics = [
      'Video e Fotografia', 'Siti Web e CRO', 'Design e UX/UI', 
      'Produttività e Soft Skills', 'Advertisement', 'Dati e Analisi',
      'E-commerce', 'Legale e Fiscalità', 'Programmazione',
      'Più visti', 'Business', 'Content Marketing',
      'Marketing', 'Team & Management', 'Startup & Imprenditoria',
      'AI & ChatGPT', 'Finanza', 'Carriera'
    ];
    
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((topic) => _buildTopicChip(topic)).toList(),
        ),
        SizedBox(height: 32),
        _buildOptionButton('Continua →'),
      ],
    );
  }

  Widget _buildOptionButton(String text) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (currentStep < totalSteps) {
            setState(() => currentStep++);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF242424),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalIdentity() {
    return Column(
      children: [
        _buildOptionButton('👨‍🎓 Studente'),
        SizedBox(height: 16),
        _buildOptionButton('👔 Dipendente'),
        SizedBox(height: 16),
        _buildOptionButton('💼 Consulente / freelance'),
        SizedBox(height: 16),
        _buildOptionButton('💡 Imprenditore'),
      ],
    );
  }

  Widget _buildCompanyRole() {
    final roles = [
      'CEO / CMO / Director',
      'Innovation Manager',
      'HR / People Manager',
      'Project / Product Manager',
      'CTO / Engineering / Developer',
      'UX / UI / Designer',
      'Ads / Traffic Manager',
      'Dati / Analytics Manager',
      'SEO Manager',
      'Growth Manager',
      'E-commerce Manager',
      'Operation Manager'
    ];

    return Column(
      children: roles.map((role) => 
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildOptionButton(role),
        )
      ).toList(),
    );
  }

  Widget _buildCompanySize() {
    final sizes = [
      'Solo io',
      '2 - 5',
      '6 - 19',
      '20 - 49',
      '50+'
    ];

    return Column(
      children: sizes.map((size) => 
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildOptionButton(size),
        )
      ).toList(),
    );
  }

  Widget _buildOnlineCourseExperience() {
    return Column(
      children: [
        _buildOptionButton('No, mai'),
        SizedBox(height: 16),
        _buildOptionButton('Ne ho seguiti alcuni'),
        SizedBox(height: 16),
        _buildOptionButton('Li seguo abitualmente'),
      ],
    );
  }

  Widget _buildReminderSettings() {
    return Column(
      children: [
        Text(
          'In che giorni?',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            'LUN', 'MAR', 'MER', 'GIO', 'VEN', 'SAB', 'DOM'
          ].map((day) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              child: Text(day[0], style: TextStyle(color: Colors.white)),
            ),
          )).toList(),
        ),
        SizedBox(height: 32),
        Text(
          'A che ora?',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 16),
        Container(
          width: 120,
          child: TextFormField(
            initialValue: '9:00',
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 32),
        _buildOptionButton('Avanti →'),
        TextButton(
          onPressed: () {
            if (currentStep < totalSteps) {
              setState(() => currentStep++);
            }
          },
          child: Text('Salta per ora', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildDiscoverySource() {
    final sources = [
      'Un amico / collega',
      'Inserzione adv',
      'Ricerca Google',
      'Facebook / Instagram',
      'TikTok',
      'LinkedIn',
      'Youtube',
      'Podcast',
      'Articolo di Blog',
      'Canali di Luca',
      'Non ricordo'
    ];

    return Column(
      children: sources.map((source) => 
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildOptionButton(source),
        )
      ).toList(),
    );
  }

  Widget _buildTopicChip(String topic) {
    return FilterChip(
      label: Text(
        topic,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      selected: false,
      onSelected: (bool selected) {
        setState(() {
          // Gestione selezione topic
        });
      },
      backgroundColor: Color(0xFF242424),
      selectedColor: Colors.yellowAccent.withOpacity(0.3),
      checkmarkColor: Colors.yellowAccent,
      side: BorderSide(color: Colors.white.withOpacity(0.1)),
    );
  }
} 