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

  // Metodo per aggiornare i coins dell'utente
void _updateCoins(int newCoins) {
  if (mounted) {
    setState(() {
      currentUser?.coins = newCoins;
    });
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
                  overflow: TextOverflow.ellipsis,
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
          // Sostituisci l'icona del fuoco e i giorni consecutivi con il Container dei coins
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.yellow, size: 25),
                const SizedBox(width: 8),
                Text(
                  '${currentUser?.coins ?? 0}', // Mostra il numero di coins
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            icon: SvgPicture.asset(
              'assets/mingcute_bookmark-fill.svg',
              color: showSavedVideos ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleSavedVideos,
          ),
        ],
      ),
    ],
  ),
),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 34,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                Container(
  width: double.infinity,  // Larghezza massima
  height: 34,
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),  // Assicurati che il padding sia corretto
  decoration: ShapeDecoration(
    color: const Color(0xFF181819),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: Center(
    child: Text(
      videoTitle,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
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
    onCoinsUpdate: _updateCoins,  // Passiamo la funzione per aggiornare i coins
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