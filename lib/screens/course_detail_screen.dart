import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/course.dart';
import 'level_screen.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/models/user.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final UserModel user;

  const CourseDetailScreen({super.key, required this.course, required this.user});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _currentPage = 0;
  int _priceButtonClicks = 0;  // Variabile per tracciare i click

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildVideoThumbnails(),
                  const SizedBox(height: 20),
                  _buildPageIndicators(),
                  const SizedBox(height: 20),
                  _buildSections(),
                  const SizedBox(height: 120), // Spazio extra per evitare che le sezioni siano coperte dai pulsanti
                ],
              ),
            ),
          ),
          if (_priceButtonClicks < 20) _buildBottomButtons(), // Mostra i pulsanti solo se non ci sono 20 click
          _buildBackButton(),
        ],
      ),
    );
  }

  // Funzione per costruire i pulsanti in basso
  Widget _buildBottomButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Riga per i due pulsanti
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2, // Pulsante Subscribe più largo
                  child: _buildSubscribeButton(),
                ),
                const SizedBox(width: 16), // Spazio tra i due pulsanti
                Expanded(
                  flex: 1, // Pulsante Prezzo più stretto
                  child: _buildPriceButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Pulsante "Subscribe" in stile SubscriptionScreen
  Widget _buildSubscribeButton() {
    return SizedBox(
      height: 60, // Più alto per dare importanza visiva
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bordi arrotondati eleganti
          ),
          elevation: 8, // Leggera ombreggiatura per effetto 3D
        ),
        child: const Text(
          'Subscribe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  // Pulsante che mostra il prezzo con contorno in stile SubscriptionScreen
  Widget _buildPriceButton() {
    return SizedBox(
      height: 60, // Altezza coerente con il pulsante Subscribe
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _priceButtonClicks++;  // Incrementa il contatore ad ogni click
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.05), // Sfondo trasparente
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bordi arrotondati
          ),
          side: BorderSide(
            color: Colors.white12, // Contorno simile al SubscriptionScreen
            width: 2, // Larghezza del contorno
          ),
          elevation: 0, // Nessuna ombreggiatura per il pulsante del prezzo
        ),
        child: const Text(
          '1,99€',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  // Funzione per ottenere il currentStep per una sezione
  int _getCurrentStepForSection(String sectionTitle) {
    return widget.user.currentSteps[sectionTitle] ?? 0; // Se non c'è progresso, restituisce 0
  }

  // Funzione per calcolare il tempo totale per completare una sezione
  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;

    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil(); // Arrotonda per eccesso
  }

  

  // Usa l'icona e il titolo insieme
// Modifica il metodo _buildSections per abilitare/disabilitare il clic
  Widget _buildSections() {
    return Column(
      children: widget.course.sections.map((section) {
        int totalTime = _calculateTotalTime(section);
        int totalVideos = section.steps.where((step) => step.type == 'video').length;
        int totalQuestions = section.steps.where((step) => step.type == 'question').length;

        // Ottieni il currentStep per la sezione dall'utente
        int currentStep = _getCurrentStepForSection(section.title);
        bool isCompleted = currentStep >= section.steps.length;

        // Usa l'icona corretta in base al completamento della sezione
        String iconAsset = isCompleted
            ? 'assets/solar_verified-check-linear.svg'
            : 'assets/ph_arrow-up-bold.svg';

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: GestureDetector(
            onTap: _priceButtonClicks >= 20 // Cliccabile solo dopo 20 click
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelScreen(section: section),
                      ),
                    );
                  }
                : null, // Disabilita il clic se non sono stati raggiunti i 20 click
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              decoration: ShapeDecoration(
                color: const Color(0xFF181819),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(29),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(section.title, iconAsset),
                  const SizedBox(height: 13),
                  _buildSectionDetails(totalTime, totalVideos, totalQuestions),
                  const SizedBox(height: 13),
                  _buildProgressBar(currentStep, section.steps.length),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  
  // Funzione che costruisce il titolo della sezione con l'icona accanto
Widget _buildSectionTitle(String title, String iconAsset) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w800,
            letterSpacing: 0.66,
          ),
        ),
      ),
      SvgPicture.asset(
        iconAsset,
        width: 24,
        height: 24,
      ),
    ],
  );
}

  // Funzione che costruisce i dettagli della sezione
  Widget _buildSectionDetails(int totalTime, int totalVideos, int totalQuestions) {
    return Row(
      children: [
        _buildDetailIconText(Icons.timer, '$totalTime minutes'),
        const SizedBox(width: 23),
        _buildDetailIconText(Icons.video_collection, '$totalVideos videos'),
        const SizedBox(width: 23),
        _buildDetailIconText(Icons.quiz, '$totalQuestions questions'),
      ],
    );
  }

  // Funzione che costruisce la barra di progresso
  Widget _buildProgressBar(int currentStep, int totalSteps) {
  return Container(
    width: double.infinity,
    height: 6,
    clipBehavior: Clip.antiAlias,
    decoration: ShapeDecoration(
      color: const Color(0xFF434348),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    child: Row(
      children: [
        Container(
          width: currentStep >= totalSteps
              ? 325.0  // Usa la larghezza massima
              : (325.0 * currentStep / totalSteps).clamp(0.0, 312.0),  // Calcola proporzione
          height: 6,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    ),
  );
}

  // Funzione che costruisce l'icona della sezione
  Widget _buildSectionIcon(String iconAsset) {
    return SvgPicture.asset(
      iconAsset,
      width: 24,
      height: 24,
    );
  }

  // Funzione che costruisce un elemento con icona e testo
  Widget _buildDetailIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF7D7D7D)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF7D7D7D),
            fontSize: 14,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.42,
          ),
        ),
      ],
    );
  }

  // Funzione che costruisce il pulsante di ritorno
  Widget _buildBackButton() {
    return Positioned(
      top: 30,
      left: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  // Funzione che costruisce le miniature video
  Widget _buildVideoThumbnails() {
    final List<LevelStep> videos = widget.course.sections
        .expand((section) => section.steps)
        .where((step) => step.type == 'video' && step.thumbnailUrl != null)
        .toList();

    return SizedBox(
      height: 371,
      child: PageView.builder(
        itemCount: videos.length,
        controller: PageController(viewportFraction: 1),
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),
            ),
            child: Image.network(
              videos[index].thumbnailUrl!,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  // Funzione che costruisce gli indicatori di pagina
  Widget _buildPageIndicators() {
  final List<LevelStep> videos = widget.course.sections
      .expand((section) => section.steps)
      .where((step) => step.type == 'video' && step.thumbnailUrl != null)
      .toList();

  return Padding(
    padding: const EdgeInsets.only(bottom: 0), // Usa Padding invece di Positioned
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(videos.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          height: 10,
          width: _currentPage == index ? 20 : 10,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    ),
  );
}
}