import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:Just_Learn/screens/subtopic_selection_sheet.dart';
import 'package:Just_Learn/screens/topic_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shorts_screen.dart';
import '../models/user.dart';
import '../models/level.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedTopic;
  String? selectedSubtopic;
  bool isLoading = true;
  UserModel? currentUser;
  List<String> allTopics = [];
  List<String> subtopics = [];
  String videoTitle = ""; // Titolo iniziale del video
  bool showSavedVideos = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (allTopics.isEmpty) {
      _loadTopicsAndUser();
    }
  }

void _toggleSavedVideos() {
  setState(() {
    showSavedVideos = !showSavedVideos; // Alterna la variabile
  });
  // Non serve ricaricare tutto qui perché la chiave cambierà e forzerà il ri-rendering
}

  Future<void> _loadTopicsAndUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (user != null || (args != null && args['isGuest'] == true)) {
      try {
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

          if (userDoc.exists) {
            final userData = userDoc.data();

            if (userData != null) {
              final userModel = UserModel.fromMap(userData);
              await _updateConsecutiveDays(userModel);

              if (mounted) {
                setState(() {
                  currentUser = userModel;
                  selectedTopic = userModel.topics.isNotEmpty ? userModel.topics.first : 'Just Learn';
                  selectedSubtopic = selectedSubtopic ?? null; // Manteniamo il subtopic se già selezionato
                });
              }
            }
          } else {
            _redirectToLogin();
          }
        } else {
          // Logica per l'ospite
          if (mounted) {
            setState(() {
              selectedTopic = 'Just Learn';
              selectedSubtopic = null;
            });
          }
        }
      } catch (e) {
        print('Error loading user: $e');
        if (mounted) {
          _redirectToLogin();
        }
      }
    } else {
      _redirectToLogin();
    }

    await _loadAllTopics();

    if (selectedTopic == null) {
      setState(() {
        selectedTopic = 'Just Learn';
        selectedSubtopic = null;
      });
    }

    if (subtopics.isEmpty) {
      await _loadSubtopics(selectedTopic!);
    }
  }

  Future<void> _updateConsecutiveDays(UserModel user) async {
    final now = DateTime.now();
    final lastAccess = user.lastAccess;
    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastAccess.year, lastAccess.month, lastAccess.day))
        .inDays;

    if (difference == 1) {
      user.consecutiveDays += 1;
    } else if (difference > 1) {
      user.consecutiveDays = 1;
    }

    user.lastAccess = now;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> _loadAllTopics() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('topics').get();
    if (mounted) {
      setState(() {
        allTopics = querySnapshot.docs.map((doc) => doc.id).toList();
        isLoading = false;
      });
    }
  }

  Future<void> _loadSubtopics(String topic) async {
  final levelsCollection = FirebaseFirestore.instance.collection('levels');
  final querySnapshot = await levelsCollection
      .where('topic', isEqualTo: topic)
      .orderBy('subtopicOrder')  // Ordina per subtopicOrder
      .orderBy('levelNumber')    // Ordina per levelNumber
      .get();
  final levels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

  final newSubtopics = levels
      .map((level) => level.subtopic ?? '')
      .where((subtopic) => subtopic.isNotEmpty)
      .toSet()
      .toList();

  if (mounted) {
    setState(() {
      subtopics = newSubtopics;
    });
  }
}

  void _selectTopic(String newTopic) async {
    if (selectedTopic != newTopic) {
      // Cambia il topic solo se diverso da quello attualmente selezionato
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'topics': [newTopic],
        });
      }

      await _loadSubtopics(newTopic);

      if (mounted) {
        setState(() {
          selectedTopic = newTopic;
          selectedSubtopic = null; // Deselezioniamo il subtopic quando cambiamo il topic
        });
      }
    }
  }

  void _selectSubtopic(String? newSubtopic) {
    setState(() {
      selectedSubtopic = newSubtopic;
      videoTitle = ''; // Resettiamo il titolo del video quando cambiamo subtopic
    });
  }

  void _openSubtopicSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => SubtopicSelectionSheet(
        subtopics: [ ...subtopics], 
        selectedSubtopic: selectedSubtopic,
        onSelectSubtopic: _selectSubtopic,
      ),
    );
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  void _updateVideoTitle(String newTitle) {
    setState(() {
      videoTitle = newTitle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () => _showTopicSelectionSheet(context),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  selectedTopic ?? 'Topic',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis, // Troncamento del testo se troppo lungo
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
      Row(
  children: [
    SvgPicture.asset(
      'assets/mdi_fire.svg', // Percorso dell'icona SVG
      color: Colors.white, // Colore dell'icona
      height: 25, // Dimensione dell'icona, equivalente all'icona precedente
      width: 25,
    ),
    const SizedBox(width: 5),
    Text(
      '${currentUser?.consecutiveDays ?? 0}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: 0.66,
      ),
    ),
          const SizedBox(width: 10),
          IconButton(
            icon: SvgPicture.asset(
              'assets/mingcute_bookmark-fill.svg',
              color: showSavedVideos ? Colors.yellow : Colors.white, // Cambia il colore se attivo
            ),
            onPressed: _toggleSavedVideos, // Funzione per alternare la visualizzazione dei video salvati
          ),
        ],
      ),
    ],
  ),
),
      body: Column(
        children: [
          SizedBox(
            width: 345,
            height: 76,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _openSubtopicSelectionSheet,
                  child: Container(
                    width: 345,
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          selectedSubtopic ?? 'Select Sub-Topic',
                          style: const TextStyle(
                            color: Colors.black,
                                                        fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: 0.48,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform(
                          transform: Matrix4.identity()..rotateZ(3.13),
                          child: const Icon(Icons.arrow_forward_ios, size: 13.91),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
  width: 345,
  height: 34,
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: ShapeDecoration(
    shape: RoundedRectangleBorder(
      side: const BorderSide(width: 1, color: Colors.white),
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: Center(
    child: Text(
      videoTitle, // La variabile che contiene il titolo del video
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis, // Per gestire titoli lunghi
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.42,
      ),
    ),
  ),
),
              ],
            ),
          ),
          Expanded(
  child: ShortsScreen(
    key: ValueKey('$selectedTopic-$selectedSubtopic-$showSavedVideos'), // Forza il ri-rendering
    selectedTopic: selectedTopic,
    selectedSubtopic: selectedSubtopic,
    onVideoTitleChange: _updateVideoTitle,
    showSavedVideos: showSavedVideos, // Passa la variabile per mostrare i video salvati
  ),
),
        ],
      ),
    );
  }

  void _showTopicSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => TopicSelectionSheet(
        allTopics: allTopics,
        selectedTopic: selectedTopic,
        onSelectTopic: _selectTopic,
      ),
    );
  }
}