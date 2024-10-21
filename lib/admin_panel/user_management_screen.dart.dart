import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchText = '';
  String _sortField = 'name';
  bool _isAscending = true;
  int _totalSubscribeClicks = 0;

  @override
  void initState() {
    super.initState();
    _getTotalSubscribeClicks(); // Carica il totale dei clic all'inizio
  }

  Future<void> _getTotalSubscribeClicks() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();
  int totalClicks = 0;

  for (var doc in querySnapshot.docs) {
    // Controlla se il documento non è nullo e contiene il campo 'subscribeClicks'
    final data = doc.data() as Map<String, dynamic>?; // Verifica se i dati non sono nulli
    if (data != null && data.containsKey('subscribeClicks')) {
      totalClicks += (data['subscribeClicks'] ?? 0) as int; // Somma i clic di ogni utente
    }
  }

  setState(() {
    _totalSubscribeClicks = totalClicks; // Aggiorna il totale dei clic
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Utenti'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Totale Click Subscribe: $_totalSubscribeClicks', // Mostra il numero totale di click
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo di ricerca
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cerca utenti...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Dropdown per ordinare gli utenti
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: _sortField,
                items: [
                  DropdownMenuItem(
                    child: Text('Nome'),
                    value: 'name',
                  ),
                  DropdownMenuItem(
                    child: Text('Email'),
                    value: 'email',
                  ),
                  DropdownMenuItem(
                    child: Text('Giorni consecutivi'),
                    value: 'consecutiveDays',
                  ),
                  DropdownMenuItem(
                    child: Text('Ultimo accesso'),
                    value: 'lastAccess',
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortField = value!;
                  });
                },
              ),
              IconButton(
                icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending;
                  });
                },
              ),
            ],
          ),
          // Elenco utenti
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return UserModel.fromMap(data);
                }).toList();

                // Filtro per ricerca
                if (_searchText.isNotEmpty) {
                  users = users.where((user) {
                    return user.name.toLowerCase().contains(_searchText.toLowerCase()) ||
                        user.email.toLowerCase().contains(_searchText.toLowerCase());
                  }).toList();
                }

                // Ordinamento
                users.sort((a, b) {
                  final aValue = a.toMap()[_sortField];
                  final bValue = b.toMap()[_sortField];
                  int comparison;
                  if (aValue is String && bValue is String) {
                    comparison = aValue.compareTo(bValue);
                  } else if (aValue is int && bValue is int) {
                    comparison = aValue.compareTo(bValue);
                  } else if (aValue is DateTime && bValue is DateTime) {
                    comparison = aValue.compareTo(bValue);
                  } else {
                    comparison = 0;
                  }
                  return _isAscending ? comparison : -comparison;
                });

                if (users.isEmpty) {
                  return Center(
                    child: Text('Nessun utente trovato', style: TextStyle(color: Colors.white)),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
  title: Text(user.name, style: TextStyle(color: Colors.white)),
  subtitle: Text(user.email, style: TextStyle(color: Colors.white)),
  trailing: user.uid != null && user.uid.isNotEmpty // Verifica se user.uid è valido
      ? StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text('Loading...', style: TextStyle(color: Colors.white));
            }
            // Cast esplicito a Map<String, dynamic>
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final userClicks = data['subscribeClicks'] ?? 0;
            
            // Se il numero di clic è diverso da 0, il testo sarà giallo, altrimenti bianco
            return Text(
              'Subscribe Clicks: $userClicks',
              style: TextStyle(
                color: userClicks != 0 ? Colors.yellowAccent : Colors.white, // Colore giallo se i click sono > 0
              ),
            );
          },
        )
      : Text('N/A', style: TextStyle(color: Colors.white)), // Gestione del caso in cui user.uid è vuoto
  onTap: () {
    // Logica per visualizzare ulteriori dettagli sull'utente
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${user.email}'),
            Text('Giorni consecutivi: ${user.consecutiveDays}'),
            Text('Ultimo accesso: ${user.lastAccess}'),
            Text('Argomenti: ${user.topics.join(', ')}'),
            ...user.WatchedVideos.entries.map((entry) => Text('${entry.key}: ${entry.value.length} video guardati')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Chiudi'),
          ),
        ],
      ),
    );
  },
);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}