import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'level_screen.dart';
import '../models/level.dart';
import '../models/user.dart';
import './access/login_screen.dart';
import '../services/level_service.dart';
import 'video_list_screen.dart'; // Importa la schermata dei video
import 'shorts_screen.dart'; // Importa la schermata degli short
import 'settings_screen.dart'; // Importa la nuova schermata delle impostazioni
import 'guest_register_prompt_screen.dart'; // Importa la schermata di registrazione per gli ospiti

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Imposta l'indice selezionato della BottomNavigationBar
  String? selectedTopic;
  bool isLoading = true;
  List<Level> levels = [];
  UserModel? currentUser;
  List<String> allTopics = [];
  bool _levelsInitialized = false;
  bool isGuest = false; // Aggiunto per tracciare se l'utente è un ospite

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Recupera gli argomenti dalla rotta solo dopo che il widget è stato inizializzato
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    isGuest = arguments?['isGuest'] ?? false;

    if (isGuest) {
      // Limita l'accesso degli ospiti a un solo livello
      _loadLevelsForGuest();
    } else {
      _loadTopicsAndUser();
    }
    _initializeLevels();
  }

  Future<void> _initializeLevels() async {
    if (!_levelsInitialized) {
      await createLevels();
      if (mounted) {
        setState(() {
          _levelsInitialized = true;
        });
      }
    }
  }

  Future<void> _loadLevelsForGuest() async {
    // Carica solo il primo livello per gli ospiti
    final levelsCollection = FirebaseFirestore.instance.collection('levels');
    final querySnapshot = await levelsCollection.orderBy('levelNumber').limit(1).get();
    final fetchedLevels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

    if (mounted) {
      setState(() {
        levels = fetchedLevels;
        isLoading = false;
      });
    }
  }

  Future<void> _loadTopicsAndUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            final userModel = UserModel.fromMap(userData);
            await _updateConsecutiveDays(userModel);
            if (mounted) {
              setState(() {
                currentUser = userModel;
                selectedTopic = userModel.topics.isNotEmpty ? userModel.topics.first : null;
              });
            }
          }
        } else {
          _redirectToLogin();
        }
      } catch (e) {
        print('Error loading user: $e');
        _redirectToLogin();
      }
    } else {
      _redirectToLogin();
    }
    await _loadAllTopics();
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
    await _loadLevels();
  }

  Future<void> _loadLevels() async {
    if (selectedTopic == null) return;
    final levelsCollection = FirebaseFirestore.instance.collection('levels');
    final querySnapshot = await levelsCollection
        .where('topic', isEqualTo: selectedTopic)
        .orderBy('levelNumber') // Ordina per levelNumber
        .get();
    final fetchedLevels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();
    if (mounted) {
      setState(() {
        levels = fetchedLevels;
        isLoading = false;
      });
    }
  }

  Future<void> updateLevelCompletion(String topic, int levelNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final userData = doc.data();
        if (userData != null) {
          final userModel = UserModel.fromMap(userData);
          final completedLevels = userModel.completedLevelsByTopic[topic] ?? [];
          if (!completedLevels.contains(levelNumber)) {
            completedLevels.add(levelNumber);
            userModel.completedLevelsByTopic[topic] = completedLevels;
            await docRef.update(userModel.toMap());
            setState(() {
              currentUser = userModel; // Aggiorna lo stato corrente dell'utente
            });
          }
        }
      }
    }
  }

  void onLevelCompleted(String? topic, int levelNumber) async {
  if (isGuest) {
    // Se l'utente è un ospite, naviga verso la schermata di registrazione
    Navigator.pushReplacementNamed(context, '/guest_register_prompt');
  } else if (topic != null) {
    await updateLevelCompletion(topic, levelNumber);
    await _loadLevels();
    if (mounted) {
      setState(() {}); // Forza l'aggiornamento della UI per riflettere il completamento del livello
    }
  } else {
    // Gestisci il caso in cui il topic sia nullo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore: nessun topic selezionato')),
    );
  }
}

  void _selectTopic(String? newTopic) async {
    if (newTopic != null && newTopic != selectedTopic) {
      if (mounted) {
        setState(() {
          selectedTopic = newTopic;
          isLoading = true;
        });
      }
      await _loadLevels();
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    _redirectToLogin();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Caricamento...'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Mappa di subtopic e livelli
    Map<String, List<Level>> levelsBySubtopic = {};
    for (var level in levels) {
      levelsBySubtopic.putIfAbsent(level.subtopic, () => []).add(level);
    }

    // Definisci le pagine in base all'indice della BottomNavigationBar
    final List<Widget> _pages = [
      _buildLevelsView(levelsBySubtopic),
      VideoListScreen(),
      ShortsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Seleziona Topic'),
                        content: Container(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: allTopics.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                title: Text(allTopics[index]),
                                onTap: () {
                                  _selectTopic(allTopics[index]);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                                child: Row(
                  children: [
                    Text(
                      selectedTopic ?? 'Topic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_drop_down, color: Colors.white, size: 28),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.white, size: 25),
                const SizedBox(width: 5),
                Text(
                  '${currentUser?.consecutiveDays ?? 0}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: 0.66,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.account_circle),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(user: currentUser),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Mostra la pagina selezionata
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.assistant_rounded),
            label: 'Livelli',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.short_text),
            label: 'Shorts', // Nuova etichetta per gli short
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildLevelsView(Map<String, List<Level>> levelsBySubtopic) {
    return ListView.builder(
      itemCount: levelsBySubtopic.keys.length,
      itemBuilder: (context, index) {
        String subtopic = levelsBySubtopic.keys.elementAt(index);
        List<Level> subtopicLevels = levelsBySubtopic[subtopic]!;
        return Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 343,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    subtopic,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ...subtopicLevels.map((level) {
                bool isCompleted = currentUser?.completedLevelsByTopic[selectedTopic]?.contains(level.levelNumber) ?? false;
                bool isCurrentLevel = !isCompleted && (currentUser?.completedLevelsByTopic[selectedTopic]?.length == level.levelNumber - 1);
                bool isLocked = !isCompleted && !isCurrentLevel && level.levelNumber != 1; // Assicurati che il primo livello sia sempre sbloccato
                return Column(
                  children: [
                    LevelCard(
                      level: level,
                      isLeft: levels.indexOf(level) % 2 == 0,
                      isCurrentLevel: isCurrentLevel,
                      isLocked: isLocked,
                      onTap: isLocked
    ? null
    : () async {
        final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LevelScreen(
      level: level,
      onLevelCompleted: () => onLevelCompleted(selectedTopic, level.levelNumber),
      isGuest: isGuest, // Passiamo isGuest a LevelScreen
    ),
  ),
);

        if (result == true) {
          if (mounted) {
            setState(() {
              _loadLevels();
            });
          }
        }
      },
                    ),
                    if (levels.indexOf(level) < levels.length - 1)
                      Container(
                        height: 110,
                        child: Center(
                          child: SvgPicture.asset(
                            levels.indexOf(level) % 2 == 0
                                ? isCompleted
                                    ? 'assets/Vector_fatto_sx.svg'
                                    : 'assets/vector_futuro_sx.svg'
                                : isCompleted
                                    ? 'assets/Vector_fatto_dx.svg'
                                    : 'assets/vector_futuro_dx.svg',
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class LevelCard extends StatelessWidget {
  final Level level;
  final bool isLeft;
  final bool isCurrentLevel;
  final bool isLocked;
  final VoidCallback? onTap;

  const LevelCard({
    Key? key,
    required this.level,
    required this.isLeft,
    required this.isCurrentLevel,
    required this.isLocked,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343,
      height: 120,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            width: 343,
            height: 96,
            padding: isLeft
                ? const EdgeInsets.only(top: 5, left: 5, right: 92, bottom: 5)
                : const EdgeInsets.only(top: 3, left: 93, right: 4, bottom: 3),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isLeft)
                  GestureDetector(
                    onTap: onTap,
                    child: buildImageContainer(level, isLocked, isCurrentLevel),
                  ),
                if (isLeft) const SizedBox(width: 21),
                Expanded(
                  child: buildTextContainer(level, isLeft, isCurrentLevel, isLocked),
                ),
                if (!isLeft) const SizedBox(width: 21),
                if (!isLeft)
                  GestureDetector(
                    onTap: onTap,
                    child: buildImageContainer(level, isLocked, isCurrentLevel),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container buildTextContainer(Level level, bool isLeft, bool isCurrentLevel, bool isLocked) {
    bool isHighlighted = isCurrentLevel || !isLocked;
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 117,
            child: Text(
              level.title,
              textAlign: isLeft ? TextAlign.left : TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: isHighlighted ? Colors.white : Color(0xFF7D7D7D),
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: 0.48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImageContainer(Level level, bool isLocked, bool isCurrentLevel) {
    return Container(
      width: 108,
      height: 86,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: isLocked ? 2 : 4,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: isLocked ? Color(0xFF7D7D7D) : Colors.white,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Transform.scale(
          scale: 1.4, // Regola questo valore per zoomare dentro/fuori
          child: Image.network(
            level.steps[0].thumbnailUrl ?? "https://via.placeholder.com/108x86",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}