import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:justlearnapp/models/user.dart';

class ApiService {
  final String baseUrl = 'http://167.99.131.91:3000/admin';

  Future<List<UserModel>> getUsers() async {
  final response = await http.get(Uri.parse('$baseUrl/users'));
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((user) => UserModel.fromMap(user)).toList();
  } else {
    print('Error fetching users: ${response.statusCode} ${response.body}');
    throw Exception('Failed to load users');
  }
}

  Future<UserModel> getUserDetails(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode == 200) {
      return UserModel.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<void> banUser(String id) async {
    final response = await http.post(Uri.parse('$baseUrl/users/ban/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to ban user');
    }
  }

  Future<void> suspendUser(String id, int duration) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/suspend/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'duration': duration}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to suspend user');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    final response = await http.get(Uri.parse('$baseUrl/statistics'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load statistics');
    }
  }
}