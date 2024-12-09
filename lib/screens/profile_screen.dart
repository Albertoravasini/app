import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentUser.name;
    _bioController.text = widget.currentUser.bio ?? 'No bio yet';
    _usernameController.text = widget.currentUser.username ?? 'username';
  }

  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .update({
        'name': _nameController.text,
        'bio': _bioController.text,
        'username': _usernameController.text,
      });

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo aggiornato con successo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'aggiornamento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = widget.currentUser.role == 'teacher';

    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Immagine di copertina
                Container(
                  width: double.infinity,
                  height: 241,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    image: DecorationImage(
                      image: NetworkImage(
                        widget.currentUser.profileImageUrl ?? 
                        'https://picsum.photos/375/241'
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Spazio per la foto profilo e il pulsante follow
                const SizedBox(height: 53), // Metà dell'altezza della foto profilo

                // Informazioni profilo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isEditing)
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                  hintText: 'Il tuo nome',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            Text(
                              widget.currentUser.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (!isEditing)
                            Container(
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isEditing)
                        TextField(
                          controller: _usernameController,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: '@username',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        Text(
                          '@${widget.currentUser.username ?? 'username'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (isEditing)
                        TextField(
                          controller: _bioController,
                          maxLines: 3,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: 'Scrivi qualcosa su di te...',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        Text(
                          widget.currentUser.bio ?? 'No bio yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Rating stars
                      Row(
                        children: [
                          ...List.generate(5, (index) => const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 18,
                          )),
                          const SizedBox(width: 8),
                          Text(
                            '26 reviews',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Subscribe button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, color: Colors.black),
                            const SizedBox(width: 8),
                            const Text(
                              'Subscribe',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '\$ 9.99 / mo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Feed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Community',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Calendar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width / 3 - 20,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFF28),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Pulsanti superiori
            Positioned(
              top: 24,
              left: 23,
              right: 23,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularButton(
                    Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                  _buildCircularButton(
                    Icons.more_horiz,
                    onPressed: () {
                      // Mostra il menu solo se è il profilo dell'utente corrente
                      if (FirebaseAuth.instance.currentUser?.uid == widget.currentUser.uid) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xFF282828),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit, color: Colors.white),
                                  title: const Text(
                                    'Modifica Profilo',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      isEditing = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Foto profilo e pulsante Follow
            Positioned(
              left: 20,
              top: 188,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto profilo con bordo staccato
                  Stack(
                    children: [
                      Container(
                        width: 106,
                        height: 106,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:  Colors.yellowAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5, // Spazio tra il bordo e l'immagine
                        top: 5,
                        child: Container(
                          width: 96, // Ridotto per lasciare spazio al bordo
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.currentUser.profileImageUrl ?? 
                                'https://picsum.photos/96',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: Image.network(
                              widget.currentUser.profileImageUrl ?? 
                              'https://picsum.photos/96',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF2A2A2A),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF51B152),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Pulsante Follow e statistiche
                  Container(
                    margin: const EdgeInsets.only(top: 32.5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 19, color: Colors.black),
                              SizedBox(width: 7),
                              Text(
                                'Follow',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '404 Follow',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Text(
                              '13 Courses',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, {required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xEA282828),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
} 