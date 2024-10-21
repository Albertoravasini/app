import 'package:Just_Learn/screens/NotificationsScreen.dart';
import 'package:Just_Learn/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'access/login_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  final UserModel? currentUser;

  const SettingsScreen({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sfondo completamente nero
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
            _buildStreakSection(), // Sezione Day Streak
            const SizedBox(height: 20),
            _buildStatsSection(context), // Sezione statistiche utente
            const SizedBox(height: 24),
            _buildPreferencesSection(context), // Sezione preferenze
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
      
      // Controlla se il giorno corrente è entro il range degli streak days e se è uguale o precedente all'ultimo accesso
      bool isComplete = currentDay.isBefore(today) || currentDay.isAtSameMomentAs(today);

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
          onTap: () {
            // Aggiungi logica per l'eliminazione dell'account
          },
          color: Colors.redAccent, // Colore rosso per eliminare
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
}