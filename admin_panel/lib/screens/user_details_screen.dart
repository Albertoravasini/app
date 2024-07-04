import 'package:flutter/material.dart';
import 'package:admin_panel/services/api_service.dart';
import 'package:justlearnapp/models/user.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  UserDetailsScreen({required this.userId});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final ApiService apiService = ApiService();
  UserModel? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final data = await apiService.getUserDetails(widget.userId);
      setState(() {
        userDetails = data;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to load user details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: Text('User Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${userDetails!.name}', style: TextStyle(fontSize: 18)),
            Text('Email: ${userDetails!.email}', style: TextStyle(fontSize: 18)),
            Text('Topics: ${userDetails!.topics.join(', ')}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text('Videos Watched:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: userDetails!.videosWatched.length,
                itemBuilder: (context, index) {
                  final video = userDetails!.videosWatched[index];
                  return ListTile(
                    title: Text(video.title),
                    subtitle: Text('Watched on: ${video.watchedAt}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}