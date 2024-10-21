import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/course_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  List<Course> courses = [];
  List<String> topics = []; // Lista dei topic
  String selectedTopic = 'All'; // Gestisce la selezione del topic
  final CourseService _courseService = CourseService();
  bool isSearching = false; // Gestisce lo stato della ricerca
  String searchText = ""; // Testo della ricerca
  UserModel? _currentUser; // Aggiungi una variabile per l'utente corrente

  @override
  void initState() {
    super.initState();
    _loadTopics();
    _loadCourses();
    _loadCurrentUser(); // Carica l'utente corrente
  }
 // Funzione per caricare l'utente corrente
  Future<void> _loadCurrentUser() async {
  try {
    final user = FirebaseAuth.instance.currentUser; // Ottieni l'utente autenticato
    if (user != null) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(); // Usa l'UID reale dell'utente
      if (userSnapshot.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(userSnapshot.data()!); // Assegna l'utente trovato a _currentUser
        });
      } else {
        print('Errore: utente non trovato in Firestore.');
      }
    } else {
      print('Errore: utente non autenticato.');
    }
  } catch (e) {
    print('Errore durante il caricamento dell\'utente: $e');
  }
}
  // Funzione per caricare i topic da Firestore
  Future<void> _loadTopics() async {
    try {
      final topicsSnapshot = await FirebaseFirestore.instance.collection('topics').get();
      if (topicsSnapshot.docs.isNotEmpty) {
        setState(() {
          topics = topicsSnapshot.docs.map((doc) => doc.id).toList();
        });
      } else {
        print("Nessun topic trovato.");
      }
    } catch (e) {
      print("Errore durante il caricamento dei topics: $e");
    }
  }

  // Funzione per caricare i corsi
  Future<void> _loadCourses() async {
    final fetchedCourses = await _courseService.getAllCourses();
    setState(() {
      courses = fetchedCourses;
    });
  }

  // Funzione per filtrare i corsi in base al topic
  void _filterCoursesByTopic(String topic) {
    setState(() {
      selectedTopic = topic;
    });
  }

  // Funzione per cercare i corsi in base al testo
  List<Course> _filterCoursesBySearchText() {
    if (searchText.isEmpty) {
      return courses.where((course) {
        return selectedTopic == 'All' || course.topic == selectedTopic;
      }).toList();
    }

    return courses.where((course) {
      final courseTitle = course.title.toLowerCase();
      final searchLower = searchText.toLowerCase();
      return courseTitle.contains(searchLower) && (selectedTopic == 'All' || course.topic == selectedTopic);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildTopicButtons(), // I pulsanti dei topic
          const SizedBox(height: 25),
          _buildCourseGrid(), // La griglia dei corsi
        ],
      ),
    );
  }

  // Funzione per costruire l'AppBar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent, // Rende trasparente lo sfondo dell'AppBar
      elevation: 0, // Rimuove l'ombra dell'AppBar
      centerTitle: false, // Non centra il titolo
      title: isSearching
          ? TextField(
              autofocus: true, // Avvia la tastiera quando si entra in modalità ricerca
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              style: TextStyle(color: Colors.white, fontSize: 18),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            )
          : Text(
              'Courses',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
              ),
            ),
      actions: [
        IconButton(
          icon: isSearching
              ? Icon(Icons.close, color: Colors.white)
              : SvgPicture.asset(
                  'assets/mdi_search.svg',
                  color: Colors.white,
                  height: 25,
                ),
          onPressed: () {
            setState(() {
              if (isSearching) {
                searchText = "";
              }
              isSearching = !isSearching;
            });
          },
        ),
      ],
    );
  }

  // Funzione per costruire i pulsanti dei topic
  Widget _buildTopicButtons() {
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSubtopicButton('All'),
            const SizedBox(width: 17),
            for (var topic in topics) ...[
              _buildSubtopicButton(topic),
              const SizedBox(width: 17),
            ],
          ],
        ),
      ),
    );
  }

  // Funzione per costruire un singolo pulsante dei topic
  Widget _buildSubtopicButton(String topic) {
    final bool isSelected = selectedTopic == topic;
    return GestureDetector(
      onTap: () => _filterCoursesByTopic(topic),
      child: Container(
        height: 53,
        padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 17),
        decoration: ShapeDecoration(
          color: Color(0xFF181819), // Colore di sfondo
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Center(
          child: Text(
            topic,
            style: TextStyle(
              color: isSelected ? Colors.white : Color(0xFF434348), // Cambia il colore del testo se selezionato
              fontSize: 16,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
              letterSpacing: 0.48,
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildCourseGrid() {
    final filteredCourses = _filterCoursesBySearchText();

    // Ottieni la larghezza dello schermo per calcolare dinamicamente il childAspectRatio
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth / 2); // Due colonne
    final double itemHeight = itemWidth * 16 / 9 + 60; // 60 è lo spazio per il titolo e il testo JustLearn

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: GridView.builder(
          itemCount: filteredCourses.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: itemWidth / itemHeight, // Rapporto basato sulle dimensioni effettive
          ),
          itemBuilder: (context, index) {
            final course = filteredCourses[index];
            return _buildCourseCard(course); // Non c'è bisogno del Center qui
          },
        ),
      ),
    );
  }

  // Funzione per costruire la card del corso
       Widget _buildCourseCard(Course course) {
    return GestureDetector(
      onTap: () {
        if (_currentUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                course: course,
                user: _currentUser!,
              ),
            ),
          );
        } else {
          print('L\'utente non è ancora caricato');
        }
      },
      child: Container(
        width: double.infinity, // Assicurati che la card usi tutta la larghezza disponibile
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (espanso per adattarsi allo spazio disponibile)
            Expanded(
              child: _buildCourseThumbnail(course), // Thumbnail riempie tutto lo spazio
            ),
            const SizedBox(height: 8), // Spazio tra la miniatura e il titolo
            // Titolo limitato a 2 righe
            Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: 0.48,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8), // Spazio tra il titolo e il testo JustLearn
            // Testo JustLearn
            const Text(
              'JustLearn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                height: 1.1,
                letterSpacing: 0.42,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Funzione per costruire la miniatura del corso mantenendo il rapporto 9:16
  Widget _buildCourseThumbnail(Course course) {
    final firstSection = course.sections.isNotEmpty ? course.sections.first : null;
    final firstVideoStep = firstSection?.steps.firstWhere(
      (step) => step.type == 'video',
    );

    final thumbnailUrl = firstVideoStep?.thumbnailUrl ?? 'https://via.placeholder.com/167x290';

    return AspectRatio(
      aspectRatio: 9/16, // Proporzione 9:16
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(thumbnailUrl),
            fit: BoxFit.cover, // Zoom dell'immagine per coprire tutta la miniatura
          ),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }}