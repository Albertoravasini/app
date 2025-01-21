import 'package:Just_Learn/web/screens/web_creator_screen.dart';
import 'package:Just_Learn/web/screens/web_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';

class WebHeader extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback? onMenuPressed;

  const WebHeader({
    Key? key,
    this.isAuthenticated = false,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Color(0xFF111111),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo e navigazione principale
          Row(
            children: [
              if (isAuthenticated) 
                IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: onMenuPressed,
                ),
              SizedBox(width: 16),
              Image.asset('assets/Just_Learn.png', height: 32),
              if (!isAuthenticated) ...[
                SizedBox(width: 48),
                _buildNavLinks(),
              ],
            ],
          ),

          // Area utente
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return _buildAuthenticatedUser(snapshot.data!);
              }
              return _buildUnauthenticatedActions(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavLinks() {
    return Row(
      children: [
        _buildNavLink('Features', isActive: true),
        SizedBox(width: 32),
        _buildNavLink('For Teachers'),
        SizedBox(width: 32),
        _buildNavLink('For Students'),
        SizedBox(width: 32),
        _buildNavLink('Pricing'),
      ],
    );
  }

  Widget _buildNavLink(String text, {bool isActive = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: isActive ? Colors.white : Colors.grey[400],
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAuthenticatedUser(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasData && userSnapshot.data != null) {
          final userData = UserModel.fromMap({
            ...userSnapshot.data!.data() as Map<String, dynamic>,
            'uid': userSnapshot.data!.id
          });
          return Row(
            children: [
              // Coins counter with animation
              _buildCoinsCounter(userData.coins),
              SizedBox(width: 24),
              // Notifications
              _buildIconButton(Icons.notifications_outlined),
              SizedBox(width: 16),
              // Profile
              _buildProfileButton(userData),
            ],
          );
        }
        return CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
        );
      },
    );
  }

  Widget _buildCoinsCounter(int coins) {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.yellowAccent,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            '$coins',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildProfileButton(UserModel userData) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.yellowAccent.withOpacity(0.5),
            Colors.yellowAccent.withOpacity(0.2),
          ],
        ),
      ),
      padding: EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF282828),
        ),
        child: userData.profileImageUrl != null && userData.profileImageUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  userData.profileImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    );
                  },
                ),
              )
            : Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildUnauthenticatedActions(BuildContext context) {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WebLoginScreen()),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[700]!),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Log in',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(width: 24),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WebCreatorScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellowAccent,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Become a Creator',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
