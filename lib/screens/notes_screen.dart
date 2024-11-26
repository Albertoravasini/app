import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFolder = '';
  List<String> _folders = [];

  // Costanti di layout
  static const double _searchBarTopPadding = 43.0;
  static const double _searchBarBottomPadding = 16.0;
  static const double _searchBarHeight = 48.0;
  static const double _folderSpacing = 11.0;
  static const double _gridPadding = 16.0;

  // Aggiungi queste variabili di stato
  String? _editingFolder;
  String? _longPressedFolder;
  final TextEditingController _folderRenameController = TextEditingController();

  // Aggiungi questa variabile per tenere traccia del testo di ricerca
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFolders();
    // Aggiungi un listener per il controller di ricerca
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadFolders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final foldersDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('note_folders')
          .get();

      setState(() {
        _folders = foldersDoc.docs.map((doc) => doc.id).toList();
        if (_folders.isNotEmpty && _selectedFolder.isEmpty) {
          _selectedFolder = _folders[0];
        }
      });
    }
  }

  Future<void> _createNewFolder(String folderName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Traccia la creazione di una nuova cartella
      Posthog().capture(
        eventName: 'folder_created',
        properties: {
          'folder_name': folderName,
        },
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('note_folders')
          .doc(folderName)
          .set({
        'createdAt': FieldValue.serverTimestamp(),
      });

      _loadFolders();
    }
  }

  // Aggiungi questo metodo per eliminare una cartella
  Future<void> _deleteFolder(String folderName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Delete Folder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this folder?',
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
            .delete();

        setState(() {
          _longPressedFolder = null;
          if (_selectedFolder == folderName) {
            _selectedFolder = _folders.isNotEmpty ? _folders[0] : '';
          }
        });
        _loadFolders();
      }
    }
  }

  // Aggiungi questo metodo per rinominare una cartella
  Future<void> _renameFolder(String oldName, String newName) async {
    if (newName.isEmpty || oldName == newName) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Crea la nuova cartella
      batch.set(userRef.collection('note_folders').doc(newName), {
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Copia tutte le note dalla vecchia alla nuova cartella
      final oldNotes = await userRef
          .collection('note_folders')
          .doc(oldName)
          .collection('notes')
          .get();

      for (var note in oldNotes.docs) {
        batch.set(
          userRef
              .collection('note_folders')
              .doc(newName)
              .collection('notes')
              .doc(note.id),
          note.data(),
        );
      }

      // Elimina la vecchia cartella
      batch.delete(userRef.collection('note_folders').doc(oldName));

      await batch.commit();

      setState(() {
        _editingFolder = null;
        _longPressedFolder = null;
        if (_selectedFolder == oldName) {
          _selectedFolder = newName;
        }
      });
      _loadFolders();
    }
  }

  // Aggiungi questo metodo per gestire il tap fuori dai folder
  void _handleTapOutside() {
    if (_longPressedFolder != null) {
      setState(() {
        _longPressedFolder = null;
        _editingFolder = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTapOutside,
      child: Container(
        color: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFolderList(),
              _buildNotesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: _searchBarTopPadding,
        bottom: _searchBarBottomPadding,
      ),
      child: Container(
        height: _searchBarHeight,
        decoration: _buildSearchBarDecoration(),
        child: _buildSearchBarContent(),
      ),
    );
  }

  Widget _buildFolderList() {
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildAddFolderButton(),
            const SizedBox(width: _folderSpacing),
            ..._buildFolderButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesGrid() {
    // Se c'è una ricerca attiva, mostra i risultati da tutte le cartelle
    if (_searchQuery.isNotEmpty) {
      return Expanded(
        child: _GlobalSearchGrid(searchQuery: _searchQuery),
      );
    }

    // Altrimenti mostra la griglia normale della cartella selezionata
    return Expanded(
      child: _selectedFolder.isEmpty
          ? const Center(
              child: Text(
                'Add A Folder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                ),
              ),
            )
          : _NotesGrid(
              folderName: _selectedFolder,
            ),
    );
  }

  BoxDecoration _buildSearchBarDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        width: 1,
        color: Colors.white.withOpacity(0.15),
      ),
    );
  }

  Widget _buildSearchBarContent() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(
            Icons.search,
            size: 24,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Montserrat',
            ),
            decoration: InputDecoration(
              hintText: 'Cerca...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFolderButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _NewFolderDialog(
            onCreateFolder: _createNewFolder,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
        decoration: ShapeDecoration(
          color: const Color(0x93333333),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            borderRadius: BorderRadius.circular(23),
          ),
        ),
        child: Text(
          'Add',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.36,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFolderButtons() {
    return _folders.map((folder) => Padding(
      padding: const EdgeInsets.only(right: _folderSpacing),
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _longPressedFolder = folder;
          });
        },
        onTap: () {
          if (_longPressedFolder == folder) {
            // Se il folder è in modalità modifica, inizia la rinomina
            setState(() {
              _editingFolder = folder;
              _folderRenameController.text = folder;
            });
          } else {
            // Altrimenti seleziona il folder normalmente
            setState(() {
              _selectedFolder = folder;
              _longPressedFolder = null;
            });
          }
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
              decoration: ShapeDecoration(
                color: const Color(0x93333333),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: _longPressedFolder == folder
                        ? Colors.red.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
              child: _editingFolder == folder
                  ? SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _folderRenameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                        autofocus: true,
                        onSubmitted: (newName) {
                          _renameFolder(folder, newName);
                        },
                        onEditingComplete: () {
                          _renameFolder(folder, _folderRenameController.text);
                        },
                      ),
                    )
                  : Text(
                      folder,
                      style: TextStyle(
                        color: _selectedFolder == folder
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.36,
                      ),
                    ),
            ),
            if (_longPressedFolder == folder)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _deleteFolder(folder),
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
      ),
    )).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Widget per la griglia delle note
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

// Aggiungi questa nuova classe per la ricerca globale
class _GlobalSearchGrid extends StatefulWidget {
  final String searchQuery;

  const _GlobalSearchGrid({
    required this.searchQuery,
  });

  @override
  _GlobalSearchGridState createState() => _GlobalSearchGridState();
}

class _GlobalSearchGridState extends State<_GlobalSearchGrid> {
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
            .snapshots(),
        builder: (context, foldersSnapshot) {
          if (!foldersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
            future: Future.wait(
              foldersSnapshot.data!.docs.map((folder) {
                return FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('note_folders')
                    .doc(folder.id)
                    .collection('notes')
                    .get();
              }).toList(),
            ),
            builder: (context, notesSnapshot) {
              if (!notesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allNotes = <Map<String, dynamic>>[];
              
              // Combina tutte le note da tutte le cartelle
              for (var i = 0; i < notesSnapshot.data!.length; i++) {
                final folderNotes = notesSnapshot.data![i].docs
                    .where((note) {
                      final title = (note['title'] ?? '').toString().toLowerCase();
                      final content = (note['content'] ?? '').toString().toLowerCase();
                      return title.contains(widget.searchQuery.toLowerCase()) ||
                          content.contains(widget.searchQuery.toLowerCase());
                    })
                    .map((note) => {
                          ...note.data() as Map<String, dynamic>,
                          'id': note.id,
                          'folderName': foldersSnapshot.data!.docs[i].id,
                        });
                allNotes.addAll(folderNotes);
              }

              if (allNotes.isEmpty) {
                return const Center(
                  child: Text(
                    'Nessuna nota trovata',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: allNotes.length,
                itemBuilder: (context, index) {
                  final note = allNotes[index];
                  return NoteCard(
                    title: note['title'] ?? '',
                    content: note['content'] ?? '',
                    noteId: note['id'],
                    folderName: note['folderName'],
                    isLongPressed: _longPressedNoteId == note['id'],
                    onLongPress: () {
                      setState(() {
                        _longPressedNoteId = note['id'];
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Aggiungi questa classe alla fine del file
class _NewFolderDialog extends StatefulWidget {
  final Function(String) onCreateFolder;

  const _NewFolderDialog({required this.onCreateFolder});

  @override
  _NewFolderDialogState createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<_NewFolderDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      title: const Text(
        'New Folder',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Montserrat',
        ),
        decoration: InputDecoration(
          hintText: 'Folder name',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontFamily: 'Montserrat',
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onCreateFolder(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text(
            'Create',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
