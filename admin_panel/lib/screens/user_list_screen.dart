import 'package:flutter/material.dart';
import 'package:admin_panel/services/api_service.dart';
import 'package:admin_panel/screens/user_details_screen.dart';
import 'package:admin_panel/screens/statistics_screen.dart';
import 'package:justlearnapp/models/user.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ApiService apiService = ApiService();
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await apiService.getUsers();
      setState(() {
        users = data;
        filteredUsers = data;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to load users: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Failed to load users');
      });
      setState(() {
        isLoading = false;
      });
    }
  }

  void _banUser(String id) async {
    try {
      await apiService.banUser(id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('User banned');
      });
      _fetchUsers(); // Refresh user list after banning a user
    } catch (e) {
      print('Failed to ban user: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Failed to ban user');
      });
    }
  }

  void _suspendUser(String id) async {
    final duration = int.tryParse(await _showInputDialog('Enter suspension duration in days'));
    if (duration != null) {
      try {
        await apiService.suspendUser(id, duration);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackBar('User suspended');
        });
        _fetchUsers(); // Refresh user list after suspending a user
      } catch (e) {
        print('Failed to suspend user: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackBar('Failed to suspend user');
        });
      }
    }
  }

  void _deleteUser(String id) async {
    try {
      await apiService.deleteUser(id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('User deleted');
      });
      _fetchUsers(); // Refresh user list after deleting a user
    } catch (e) {
      print('Failed to delete user: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Failed to delete user');
      });
    }
  }

  void _showSnackBar(String message) {
    final context = _scaffoldKey.currentContext!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String> _showInputDialog(String title) async {
    String input = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            onChanged: (value) {
              input = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
    return input;
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final nameLower = user.name.toLowerCase();
        final emailLower = user.email.toLowerCase();
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) || emailLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('User List'),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatisticsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) => _filterUsers(query),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.block),
                        onPressed: () => _banUser(user.uid),
                      ),
                      IconButton(
                        icon: Icon(Icons.timer),
                        onPressed: () => _suspendUser(user.uid),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteUser(user.uid),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailsScreen(userId: user.uid),
                      ),
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