import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final String role; // 'citizen' or 'admin'
  final int points;
  final List<String> badges;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    this.photoURL,
    this.role = 'citizen', // Default role on signup
    this.points = 0, // Default points on signup
    this.badges = const [], // Default empty list of badges
    required this.createdAt,
  });

  /// Factory constructor to create a UserModel from a Firestore document Map.
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      photoURL: map['photoURL'],
      role: map['role'] ?? 'citizen',
      points: map['points'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  /// Converts the UserModel instance to a Map for storing in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'role': role,
      'points': points,
      'badges': badges,
      'createdAt': createdAt,
    };
  }
}
