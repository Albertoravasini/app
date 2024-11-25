import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class NoteEditorScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String folderName;
  String? noteId;

  NoteEditorScreen({
    Key? key,
    this.initialTitle,
    this.initialContent,
    required this.folderName,
    this.noteId,
  }) : super(key: key);

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  String _lastSavedTitle = '';
  String _lastSavedContent = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _lastSavedTitle = widget.initialTitle ?? '';
    _lastSavedContent = widget.initialContent ?? '';

    _titleController.addListener(_onChangeDebounced);
    _contentController.addListener(_onChangeDebounced);
  }

  Timer? _debounceTimer;

  void _onChangeDebounced() {
    if (_isSaving) return;

    final currentTitle = _titleController.text.trim();
    final currentContent = _contentController.text.trim();

    if (currentTitle == _lastSavedTitle && currentContent == _lastSavedContent) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed) {
        _saveNote();
      }
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving || _isDisposed) return;

    final currentTitle = _titleController.text.trim();
    final currentContent = _contentController.text.trim();

    if (currentTitle == _lastSavedTitle && currentContent == _lastSavedContent) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final noteData = {
        'title': currentTitle,
        'content': currentContent,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final notesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('note_folders')
          .doc(widget.folderName)
          .collection('notes');

      if (widget.noteId != null) {
        await notesRef.doc(widget.noteId).update(noteData);
      } else {
        noteData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await notesRef.add(noteData);
        widget.noteId = docRef.id;
      }

      _lastSavedTitle = currentTitle;
      _lastSavedContent = currentContent;
    } catch (e) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel salvare la nota')),
        );
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _forceSaveAndPop() async {
    _debounceTimer?.cancel();

    final currentTitle = _titleController.text.trim();
    final currentContent = _contentController.text.trim();

    if (currentTitle != _lastSavedTitle || currentContent != _lastSavedContent) {
      await _saveNote();
    }

    if (!_isDisposed && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _forceSaveAndPop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _forceSaveAndPop,
          backgroundColor: const Color(0x93333333),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Montserrat',
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Write here your note...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Montserrat',
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    
    final currentTitle = _titleController.text.trim();
    final currentContent = _contentController.text.trim();
    if (currentTitle != _lastSavedTitle || currentContent != _lastSavedContent) {
      _saveNote();
    }

    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

// Widget per il pulsante di creazione nuova nota
class NewNoteButton extends StatelessWidget {
  final String folderName;

  const NewNoteButton({required this.folderName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(
              folderName: folderName,
            ),
          ),
        );
      },
      child: Container(
        decoration: ShapeDecoration(
          color: const Color(0x93333333),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 40,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

// Widget per la card della nota
class NoteCard extends StatelessWidget {
  final String title;
  final String content;
  final String noteId;
  final String folderName;
  final bool isLongPressed;
  final VoidCallback onLongPress;

  const NoteCard({
    required this.title,
    required this.content,
    required this.noteId,
    required this.folderName,
    required this.isLongPressed,
    required this.onLongPress,
  });

  Future<void> _deleteNote(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Delete Note',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('note_folders')
            .doc(folderName)
            .collection('notes')
            .doc(noteId)
            .delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!isLongPressed) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                folderName: folderName,
                noteId: noteId,
                initialTitle: title,
                initialContent: content,
              ),
            ),
          );
        }
      },
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: const Color(0x93333333),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: isLongPressed 
                      ? Colors.red.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    content,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (isLongPressed)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _deleteNote(context),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesGrid extends StatefulWidget {
  final String folderName;

  const _NotesGrid({
    required this.folderName,
  });

  @override
  _NotesGridState createState() => _NotesGridState();
}

class _NotesGridState extends State<_NotesGrid> {
  String? _longPressedNoteId;

  void _handleTapOutside() {
    if (_longPressedNoteId != null) {
      setState(() {
        _longPressedNoteId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTapOutside,
      behavior: HitTestBehavior.translucent,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('note_folders')
            .doc(widget.folderName)
            .collection('notes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 0,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: notes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return NewNoteButton(folderName: widget.folderName);
              }

              final note = notes[index - 1];
              return NoteCard(
                title: note['title'] ?? '',
                content: note['content'] ?? '',
                noteId: note.id,
                folderName: widget.folderName,
                isLongPressed: _longPressedNoteId == note.id,
                onLongPress: () {
                  setState(() {
                    _longPressedNoteId = note.id;
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
} 