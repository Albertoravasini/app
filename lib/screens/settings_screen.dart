import 'package:Just_Learn/firebase_options.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/screens/NotificationsScreen.dart';
import 'package:Just_Learn/screens/subscription_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'access/login_screen.dart';
import 'privacy_policy_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:Just_Learn/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  final UserModel? currentUser;

  const SettingsScreen({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildWelcomeSection(),
            if (currentUser?.role == 'teacher')
              _buildTeacherDashboard(),
            const SizedBox(height: 20),
            _buildStreakSection(),
            const SizedBox(height: 20),
            _buildStatsSection(context),
            const SizedBox(height: 24),
            _buildPreferencesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Builder(
      builder: (BuildContext context) => Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (currentUser == null) return;
                      await ImageService.uploadProfileImage(
                        userId: currentUser!.uid,
                        isProfileImage: true,
                        context: context,
                      );
                    },
                    child: Container(
                      width: 72,
                      height: 73,
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        image: DecorationImage(
                          image: NetworkImage(currentUser?.profileImageUrl ?? "https://via.placeholder.com/72x73"),
                          fit: BoxFit.cover,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentUser?.name ?? 'User',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 23),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: ShapeDecoration(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: Colors.white.withOpacity(0.10),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: InkWell(
                onTap: () async {
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Errore: Utente non trovato'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (currentUser?.role == 'teacher') {
                    // Se l'utente è già un insegnante, naviga al suo profilo
                    Navigator.pushNamed(
                      context,
                      '/profile',
                      arguments: currentUser,
                    );
                  } else {
                    // Se l'utente non è un insegnante, apri il link Calendly
                    final Uri url = Uri.parse('https://calendly.com/ravasini-aziendale/become-a-teacher-on-justlearn');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossibile aprire il link'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Become a teacher',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.84,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSection() {
    List<String> weekDays = ["M", "T", "W", "T", "F", "S", "S"];
    int streakDays = currentUser?.consecutiveDays ?? 0;
    DateTime today = DateTime.now();
    DateTime lastAccess = currentUser?.lastAccess ?? today;

    // Calcola la differenza in giorni tra oggi e l'ultimo accesso
    int differenceInDays = today.difference(lastAccess).inDays;

    // Aggiorna il numero di streak in base alla differenza temporale
    if (differenceInDays == 0) {
      // Se l'ultimo accesso è stato oggi, non modificare streakDays ma segna il giorno come completo
      streakDays = currentUser?.consecutiveDays ?? 0;
    } else if (differenceInDays == 1) {
      // Se l'accesso è stato ieri, aumenta la streak
      streakDays += 1;
    } else if (differenceInDays > 1) {
      // Se l'ultimo accesso è stato più di un giorno fa, resetta la streak
      streakDays = 0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Sfondo leggermente più chiaro per la card
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.yellowAccent,
            size: 60,
          ),
          const SizedBox(height: 8),
          Text(
            '$streakDays',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Week Streak',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You are doing really great, ${currentUser?.name ?? 'User'}!',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildScrollableWeekDays(streakDays, weekDays, lastAccess),
        ],
      ),
    );
  }

  Widget _buildScrollableWeekDays(int streakDays, List<String> weekDays, DateTime lastAccess) {
    DateTime today = DateTime.now();
    
    // Trova la data del lunedì della settimana corrente
    DateTime monday = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(weekDays.length, (index) {
        // Calcola la data per ogni giorno della settimana partendo dal lunedì
        DateTime currentDay = monday.add(Duration(days: index));
        
        // Marca il giorno come completato solo se rientra nella streak e non va oltre l'ultimo accesso
        bool shouldMarkDay = currentDay.isBefore(lastAccess.add(Duration(days: 1))) && (index < streakDays || currentDay.isAtSameMomentAs(today));

        // Controlla se il giorno è passato
        bool isPast = currentDay.isBefore(today);

        return Column(
          children: [
            Text(
              weekDays[index], // Mostra il giorno della settimana (L, M, ...)
              style: TextStyle(
                color: isPast ? Colors.grey : Colors.white, // Usa grigio per i giorni passati
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 36, // Dimensioni del cerchio contenente la data
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: shouldMarkDay ? Colors.yellowAccent : Colors.transparent,
              ),
              child: Center(
                child: shouldMarkDay
                    ? const Icon(Icons.check, color: Colors.grey, size: 20) // Pallino riempito se completo
                    : Text(
                        '${currentDay.day}', // Mostra il numero del giorno del mese
                        style: TextStyle(
                          color: isPast ? Colors.grey : Colors.white, // Usa grigio per i giorni passati
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    int totalVideosWatched = currentUser?.WatchedVideos.values.expand((videos) => videos).length ?? 0;
    int totalQuestionsAnswered = currentUser?.answeredQuestions.values.expand((questions) => questions).length ?? 0;
    int totalCoins = currentUser?.coins ?? 0; // Recupera i coins dell'utente

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Sfondo leggermente più chiaro
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Days', '${currentUser?.consecutiveDays ?? 0}'),
              _buildStatItem('Videos', '$totalVideosWatched'),
              _buildStatItem('Questions', '$totalQuestionsAnswered'),
              _buildStatItem('Coins', '$totalCoins'), // Mostra i coins invece dei minuti
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()), // Naviga alla SubscriptionScreen
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333), // Colore per il bottone scuro
              side: const BorderSide(color: Colors.purpleAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.insights, color: Colors.purpleAccent),
                SizedBox(width: 8),
                Text('2 Insights Available', style: TextStyle(color: Colors.purpleAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Testo bianco per il valore
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey, // Testo grigio per il label
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreferenceItem(
          context,
          icon: Icons.notifications,
          title: 'Notifications',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
          },
        ),
        _buildPreferenceItem(
          context,
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
          },
        ),
        _buildPreferenceItem(
          context,
          icon: Icons.delete,
          title: 'Delete Account',
          onTap: () => _showDeleteAccountDialog(context),
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This action cannot be undone. Please enter your credentials to confirm.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Riautenticare l'utente
                            User? user = FirebaseAuth.instance.currentUser;
                            AuthCredential credential = EmailAuthProvider.credential(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                            );
                            await user?.reauthenticateWithCredential(credential);
                            
                            // Eliminare l'account
                            await user?.delete();
                            
                            // Eliminare i dati dell'utente da Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user?.uid)
                                .delete();
                            
                            // Reindirizzare alla schermata di login
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          } catch (e) {
                            // Mostrare un messaggio di errore
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error: ${e.toString()}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherDashboard() {
    if (currentUser?.role != 'teacher') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con stile simile a profile_screen
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(currentUser?.coverImageUrl ?? 'https://picsum.photos/375/200'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Overlay gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Contenuto
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Insegnante',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              currentUser?.profileImageUrl ?? 'https://picsum.photos/40/40',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            currentUser?.name ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Statistiche in stile card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                _buildStatCard(
                  'Studenti',
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data?['followers']?.length ?? 0}',
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Icons.people,
                  Colors.yellowAccent,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Guadagno',
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('teacherId', isEqualTo: currentUser?.uid)
                        .where('date', isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
                        .snapshots(),
                    builder: (context, snapshot) {
                      final earnings = snapshot.data?.docs.fold<double>(
                        0,
                        (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['amount'] as double,
                      ) ?? 0;
                      return Text(
                        '€${earnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Icons.euro,
                  Colors.greenAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, Widget value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            value,
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      return 'Ieri';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}