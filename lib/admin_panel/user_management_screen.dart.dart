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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Utenti', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
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
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
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

                if (_searchText.isNotEmpty) {
                  users = users.where((user) {
                    return user.name.toLowerCase().contains(_searchText.toLowerCase()) ||
                        user.email.toLowerCase().contains(_searchText.toLowerCase());
                  }).toList();
                }

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
                  return Center(child: Text('Nessun utente trovato', style: TextStyle(color: Colors.white)));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user.name, style: TextStyle(color: Colors.white)),
                      subtitle: Text(user.email, style: TextStyle(color: Colors.white)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(user.name, style: TextStyle(color: Colors.black)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Email: ${user.email}', style: TextStyle(color: Colors.black)),
                                Text('Livelli completati: ${user.completedLevelsByTopic.length}', style: TextStyle(color: Colors.black)),
                                Text('Giorni consecutivi: ${user.consecutiveDays}', style: TextStyle(color: Colors.black)),
                                Text('Ultimo accesso: ${user.lastAccess}', style: TextStyle(color: Colors.black)),
                                Text('Argomenti: ${user.topics.join(', ')}', style: TextStyle(color: Colors.black)),
                                ...user.savedVideosByTopic.entries.map((entry) => Text('${entry.key}: ${entry.value.length} video', style: TextStyle(color: Colors.black))),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Chiudi', style: TextStyle(color: Colors.black)),
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