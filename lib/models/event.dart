import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String teacherId;
  final int maxParticipants;
  final List<String> participants;
  final bool isOnline;
  final String? meetingLink;
  final String? location;
  final double? price;
  final String? imageUrl;
  final bool isSubscriptionRequired;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.teacherId,
    required this.maxParticipants,
    this.participants = const [],
    required this.isOnline,
    this.meetingLink,
    this.location,
    this.price,
    this.imageUrl,
    this.isSubscriptionRequired = false,
  });

  factory Event.fromMap(Map<String, dynamic> data, String id) {
    List<String> parseParticipants(dynamic participantsData) {
      if (participantsData == null) return [];
      if (participantsData is List) {
        return participantsData.map((e) => e.toString()).toList();
      }
      return [];
    }

    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      teacherId: data['teacherId'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
      participants: parseParticipants(data['participants']),
      isOnline: data['isOnline'] ?? false,
      meetingLink: data['meetingLink'],
      location: data['location'],
      price: (data['price'] as num?)?.toDouble(),
      imageUrl: data['imageUrl'],
      isSubscriptionRequired: data['isSubscriptionRequired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'teacherId': teacherId,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'isOnline': isOnline,
      'meetingLink': meetingLink,
      'location': location,
      'price': price,
      'imageUrl': imageUrl,
      'isSubscriptionRequired': isSubscriptionRequired,
    };
  }

  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  bool get isFull {
    return participants.length >= maxParticipants;
  }
} 