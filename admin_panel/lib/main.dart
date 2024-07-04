import 'package:flutter/material.dart';
import 'package:admin_panel/screens/user_list_screen.dart';
import 'package:admin_panel/screens/user_details_screen.dart';
import 'package:admin_panel/screens/statistics_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => UserListScreen(),
        '/users/:id': (context) => UserDetailsScreen(userId: ModalRoute.of(context)!.settings.arguments as String),
        '/statistics': (context) => StatisticsScreen(),
      },
    );
  }
}