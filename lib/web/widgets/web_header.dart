import 'package:Just_Learn/web/screens/web_creator_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';

class WebHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      color: const Color(0xFF181819),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/logo.png', height: 40),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(snapshot.data!.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasData && userSnapshot.data != null) {
                      final userData = UserModel.fromMap(
                        {...userSnapshot.data!.data() as Map<String, dynamic>, 'uid': userSnapshot.data!.id}
                      );
                      return Row(
                        children: [
                          // Coins counter
                          Container(
                            height: 32,
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.only(right: 16),
                            decoration: ShapeDecoration(
                              color: const Color(0x93333333),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.yellowAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${userData.coins}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Profile Icon/Image
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF282828),
                              border: Border.all(
                                color: Colors.yellowAccent,
                                width: 2,
                              ),
                            ),
                            child: userData.profileImageUrl != null && userData.profileImageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      userData.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 24,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ],
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                );
              }
              // Pulsante "Become a Creator" per utenti non autenticati
              return ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WebCreatorScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Become a Creator',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
