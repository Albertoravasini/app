import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Importa flutter_svg
import 'package:share_plus/share_plus.dart'; // Import share_plus package
import 'package:cloud_firestore/cloud_firestore.dart'; // Per Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Per Firebase Auth

class ShareVideoScreen extends StatefulWidget {
  final String videoLink;
  final VoidCallback onClose; 

  const ShareVideoScreen({super.key, required this.videoLink, required this.onClose});

  @override
  _ShareVideoScreenState createState() => _ShareVideoScreenState();
}

class _ShareVideoScreenState extends State<ShareVideoScreen> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfVideoIsSaved();
  }

  Future<void> _checkIfVideoIsSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];
        final videoId = _extractVideoId(widget.videoLink);

        setState(() {
          isSaved = savedVideos.any((video) => video['videoId'] == videoId);
        });
      }
    }
  }

  Future<void> _saveVideo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];
        final videoId = _extractVideoId(widget.videoLink);

        savedVideos.add({
          'videoId': videoId,
          'title': 'Saved Video',
          'savedAt': DateTime.now().toIso8601String(),
        });

        await userDocRef.update({'SavedVideos': savedVideos});
        setState(() {
          isSaved = true;
        });
      }
    }
  }

  Future<void> _unsaveVideo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];
        final videoId = _extractVideoId(widget.videoLink);

        savedVideos.removeWhere((video) => video['videoId'] == videoId);

        await userDocRef.update({'SavedVideos': savedVideos});
        setState(() {
          isSaved = false;
        });
      }
    }
  }

  String _extractVideoId(String url) {
    final Uri uri = Uri.parse(url);
    return uri.queryParameters['v'] ?? uri.pathSegments.last;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
          widget.onClose(); 
        }
      },
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height, 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isSaved) {
                          _unsaveVideo();
                        } else {
                          _saveVideo();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 1, color: Colors.white),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/mingcute_bookmark-fill.svg',
                              width: 23,
                              height: 23,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              isSaved ? 'Unsave Video' : 'Save Video',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                letterSpacing: 0.48,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 21),
                    // Share With Friends Button
                    GestureDetector(
                      onTap: () {
                        // Testo personalizzato da includere con il link
                        String customMessage = '''
Watch this video: ${widget.videoLink}

I found this video on JustLearn: https://apps.apple.com/it/app/justlearn/id6508169503

The Only Educational Scrolling App ⚡️''';

                        // Condividi il messaggio personalizzato insieme al link
                        Share.share(customMessage);
                      },
                      child: Container(
                        width: double.infinity, // Prende tutta la larghezza disponibile
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 1, color: Colors.white),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Usa l'icona SVG al posto di Icons.save_alt
                            SvgPicture.asset(
                              'assets/icona_share.svg',
                              width: 23, // Imposta la dimensione dell'icona SVG
                              height: 23,
                              color: Colors.white, // Se vuoi applicare un colore (puoi rimuovere se non necessario)
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Share With Friends',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                letterSpacing: 0.48,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Spazio per la BottomNavigationBar, se necessario
              SizedBox(
                height: 80, // Spazio per la BottomNavigationBar
                child: Container(
                  color: Colors.transparent, // Colore trasparente o lasciare vuoto
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}