import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPlan = 'annual'; // Pre-selezionato il piano annuale
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
void initState() {
  super.initState();
  

}

  Future<void> _incrementClickCount() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Incrementa solo il contatore specifico per l'utente
    await _firestore.collection('users').doc(user.uid).set(
      {
        'subscribeClicks': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Pro Plan'),
        centerTitle: true,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuisce uniformemente lo spazio verticale
          children: [
            // Icona in evidenza
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: Colors.yellowAccent,
                size: 64,
              ),
            ),

            // Titolo grande e attraente
            const Text(
              'Upgrade to Pro',
              style: TextStyle(
                fontSize: 28, // Leggermente ridotto per far stare tutto
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: Colors.white,
              ),
            ),

            // Descrizione
            const Text(
              'Unlock the full learning experience with these exclusive features:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, // Font ridotto per migliorare il layout
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.4,
              ),
            ),

            // Card con i benefici
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  FeatureItem(
                    icon: Icons.school_rounded,
                    text: 'Unlimited access to all courses',
                  ),
                  SizedBox(height: 8),
                  FeatureItem(
                    icon: Icons.quiz_rounded,
                    text: 'Unlimited access to all quizzes',
                  ),
                  SizedBox(height: 8),
                  FeatureItem(
                    icon: Icons.refresh_rounded,
                    text: 'Unlock Quiz for mistakes and daily quizzes',
                  ),
                  SizedBox(height: 8),
                  FeatureItem(
                    icon: Icons.assistant_rounded,
                    text: 'Unlock Beta AI assistant for learning',
                  ),
                ],
              ),
            ),

            // Sezione per la selezione del piano
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildPlanOption(
                    title: 'Annually',
                    originalPrice: '\$59.88',
                    discountedPrice: '\$29.99 / year',
                    discountLabel: '-53%',
                    isSelected: selectedPlan == 'annual',
                    onTap: () {
                      setState(() {
                        selectedPlan = 'annual';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlanOption(
                    title: 'Monthly',
                    discountedPrice: '\$9.99 / month',
                    isSelected: selectedPlan == 'monthly',
                    onTap: () {
                      setState(() {
                        selectedPlan = 'monthly';
                      });
                    },
                  ),
                ),
              ],
            ),

            // Pulsante Subscribe
SizedBox(
  width: double.infinity, // Larghezza piena
  child: ElevatedButton(
    onPressed: () async {
      await _incrementClickCount(); // Incrementa il contatore per l'utente

      // Registra l'evento su Firebase Analytics
    

      // Mostra la Snackbar quando l'utente clicca su "Subscribe"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The premium version will be available soon!'),
          duration: Duration(seconds: 3), // Durata della Snackbar
        ),
      );

      print('Subscribed to: $selectedPlan plan');
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.yellowAccent,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: const Text(
      'Subscribe',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

            // Pulsante Maybe Later
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metodo per creare una card di selezione piano
  Widget _buildPlanOption({
    required String title,
    String? originalPrice,
    required String discountedPrice,
    String? discountLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.yellowAccent : Colors.white12,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (originalPrice != null)
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.yellowAccent,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  discountedPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (discountLabel != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    discountLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.yellowAccent,
          size: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}