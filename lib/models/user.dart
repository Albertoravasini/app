class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> topics;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.topics,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      topics: List<String>.from(data['topics']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'topics': topics,
    };
  }
}