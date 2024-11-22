import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isEditing = false;
  String _currentNote = '';

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final noteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc('learning_notes')
          .get();

      if (noteDoc.exists) {
        setState(() {
          _currentNote = noteDoc.data()?['content'] ?? '';
          _noteController.text = _currentNote;
        });
      }
    }
  }

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc('learning_notes')
          .set({
        'content': _noteController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentNote = _noteController.text;
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
            child: Row(
              children: [
                Text(
                  'Le mie note',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isEditing
                  ? TextField(
                      controller: _noteController,
                      maxLines: null,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Scrivi le tue note qui...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: Text(
                        _currentNote.isEmpty
                            ? 'Tocca per aggiungere una nota'
                            : _currentNote,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saveNote,
                child: Text('Salva'),
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.yellowAccent,
                  backgroundColor: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
