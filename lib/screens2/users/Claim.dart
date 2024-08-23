import 'package:cloud_firestore/cloud_firestore.dart';

class Claim {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String phone;
  final String email;
  final String imageUrl;
  final GeoPoint? position; // Make GeoPoint nullable
  final Timestamp timestamp;

  Claim({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.phone,
    required this.email,
    required this.imageUrl,
    required this.position,
    required this.timestamp,
  });

  factory Claim.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    GeoPoint? geoPoint = data['position'] as GeoPoint?; // GeoPoint can be null
    return Claim(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      position: geoPoint,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
