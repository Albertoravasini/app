import 'package:Just_Learn/widgets/question_card.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/video_service.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class LevelScreen extends StatefulWidget {
  final Level level;
  final VoidCallback onLevelCompleted;
  final int initialStepIndex;  // Nuovo parametro per l'indice iniziale
  final bool isGuest;

  LevelScreen({
    required this.level,
    required this.onLevelCompleted,
    this.initialStepIndex = 0,  // Imposta il valore predefinito su 0
    this.isGuest = false,  // Imposta il valore predefinito su false
  });

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  late int currentStepIndex;
  bool isAnswered = false;
  bool isCorrect = false;
  double videoProgress = 0.0;
  int checkpoint = 0;
  List<Map<String, dynamic>> subtitles = [];
  String displayedText = '';
  bool subtitlesAvailable = true; // Variabile per controllare se i sottotitoli sono disponibili
  

  late YoutubePlayerController _youtubeController;
  final ScrollController _scrollController = ScrollController();

  LevelStep get currentStep => widget.level.steps[currentStepIndex];

  @override
  void initState() {
    super.initState();
    currentStepIndex = widget.initialStepIndex;  // Inizializza l'indice dello step corrente
    _initializeController();
    _initializePlayer();
    _fetchVideoText(currentStep.content);
  }

  @override
  void dispose() {
    _youtubeController.removeListener(_videoProgressListener);
    _youtubeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeController() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: currentStep.content,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    )..addListener(_videoProgressListener);
  }

  void _initializePlayer() {
    _youtubeController.addListener(() {
      if (_youtubeController.value.isReady && !_youtubeController.value.hasPlayed) {
        _loadCheckpoint();
      }
    });
  }

  void _videoProgressListener() {
    if (_youtubeController.value.isReady && !_youtubeController.value.isFullScreen) {
      setState(() {
        final position = _youtubeController.value.position;
        final duration = _youtubeController.metadata.duration;
        if (duration.inSeconds > 0) {
          videoProgress = position.inSeconds / duration.inSeconds;
          int newCheckpoint = position.inSeconds;
          if (newCheckpoint > checkpoint) {
            checkpoint = newCheckpoint;
            _saveCheckpoint(checkpoint);
          }

          _updateDisplayedText(position.inSeconds);
        }
      });
    }
  }

  void _updateDisplayedText(int currentTime) {
    final currentWords = subtitles.where((subtitle) {
      final wordTimestamp = subtitle['timestamp'];
      return currentTime >= wordTimestamp;
    }).toList();

    // Mostra tutte le parole fino al timestamp corrente
    setState(() {
      displayedText = currentWords.map((subtitle) => subtitle['word']).join(' ');
    });

    // Scorrimento automatico verso il basso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadCheckpoint() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        final lastCheckpoint = userModel.checkpoints[widget.level.levelNumber.toString()];
        if (lastCheckpoint != null) {
          setState(() {
            checkpoint = lastCheckpoint;
          });

          final position = Duration(seconds: lastCheckpoint);
          _youtubeController.seekTo(position);
          _youtubeController.play();
        }
      }
    }
  }

  Future<void> _saveCheckpoint(int checkpoint) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        if (userModel.checkpoints[widget.level.levelNumber.toString()] != checkpoint) {
          userModel.checkpoints[widget.level.levelNumber.toString()] = checkpoint;
          await docRef.update(userModel.toMap());
        }
      }
    }
  }

  Future<void> _fetchVideoText(String videoId) async {
    try {
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final subtitlesData = await VideoService().fetchVideoText(videoUrl);
      setState(() {
        subtitles = subtitlesData.map<Map<String, dynamic>>((subtitle) => subtitle as Map<String, dynamic>).toList();
        subtitlesAvailable = true;
      });
    } catch (e) {
      print('Failed to fetch video text: $e');
      setState(() {
        subtitlesAvailable = false; // Imposta la variabile a false se il caricamento dei sottotitoli fallisce
      });
    }
  }

  void _requestSubtitlesWithAuth() async {
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/auth', {
      'client_id': '666035353608-51dreihqbgdcbk17ga7ijs5c1sv8rb9q.apps.googleusercontent.com',
      'redirect_uri': 'justlearnapp://justlearnapp.com/oauth2callback',  // URI di reindirizzamento configurato
      'response_type': 'token',  // Puoi usare 'code' per authorization code flow, 'token' per implicit flow
      'scope': 'https://www.googleapis.com/auth/youtube.readonly',
      'state': 'iphne',  // Stato per prevenzione CSRF
      'include_granted_scopes': 'true',
      'access_type': 'offline',  // Facoltativo, utile per ottenere un refresh token
    }); // URL di autenticazione OAuth con i parametri appropriati
    final callbackUrlScheme = 'justlearnapp';  // Lo schema configurato per il deep linking

    try {
      // Avvia il flusso OAuth
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'justlearnapp',
      );

      // Estrai il token di accesso dall'URL di callback
      final token = Uri.parse(result).queryParameters['access_token'];

      // Utilizza il token di accesso per scaricare i sottotitoli
      if (token != null) {
        print("Token ricevuto: $token");
        // Aggiungi qui la logica per usare il token
      }
    } catch (e) {
      print('Errore durante l\'autenticazione: $e');
    }
  }

  void handleAnswer(bool correct) {
    setState(() {
      isAnswered = true;
      isCorrect = correct;
    });
  }

  void nextStep() {
  setState(() {
    if (currentStepIndex < widget.level.steps.length - 1) {
      currentStepIndex++;
      isAnswered = false;
      isCorrect = false;
      if (currentStep.type == 'video') {
        _initializeController();
        _fetchVideoText(currentStep.content);
      }
    } else {
      // Chiama la funzione onLevelCompleted una volta che l'ultimo step è completato
      widget.onLevelCompleted();

      // Se l'utente è registrato, torna alla schermata precedente
      if (!widget.isGuest) {
  Navigator.pop(context, true);  // Torna indietro solo se l'utente non è un ospite
}
    }
  });
}

  void resetToFirstStep() {
    setState(() {
      currentStepIndex = 0;
      isAnswered = false;
      isCorrect = false;
      _initializeController();
      _fetchVideoText(currentStep.content);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Impedisce il ritorno accidentale
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Livello ${widget.level.levelNumber}'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              borderRadius: BorderRadius.circular(10),
              minHeight: 15,
              value: (currentStepIndex + 1) / widget.level.steps.length,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),            
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: currentStep.type == 'video'
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: YoutubePlayer(
                            controller: _youtubeController,
                            showVideoProgressIndicator: true,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: subtitlesAvailable
                              ? SingleChildScrollView(
                                  controller: _scrollController,
                                  child: Text(
                                    displayedText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                )
                              : Center(
                                  child: ElevatedButton(
                                    onPressed: _requestSubtitlesWithAuth,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(width: 1, color: Colors.white),
                                      ),
                                    ),
                                    child: Text(
                                      'Attiva Sottotitoli',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    )
                  : QuestionCard(step: currentStep, onAnswered: handleAnswer),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: currentStep.type == 'video'
                ? ElevatedButton(
                    onPressed: nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(343, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Continua',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: resetToFirstStep,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(width: 1, color: Colors.white),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: GestureDetector(
                          onTap: isAnswered ? nextStep : null,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(width: 1, color: Colors.white),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Domanda',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}