import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String? id;
  final String submittedBy; // User UID - The primary link to the user
  final String? submittedByName; // Denormalized user's display name for easy access
  final String? submittedByPhotoUrl; // Denormalized user's photo URL
  final Timestamp createdAt;
  // The precise coordinates for mapping
  final GeoPoint coordinates; 
  
  // A human-readable, structured address for display and filtering
  final Map<String, String?> address;
  final String description;
  final String? imageUrl;
  final String status;
  final String category;

  ReportModel({
    this.id,
    required this.submittedBy,
    this.submittedByName,
    this.submittedByPhotoUrl,
    required this.createdAt,
    required this.coordinates,
    required this.address,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.category,
  });

  /// A computed property to get a quick, "Zomato-like" display name.
  /// Example: "Connaught Place, New Delhi"
  String get locationName {
    final area = address['subLocality'] ?? address['locality'] ?? '';
    final city = address['city'] ?? '';
    if (area.isNotEmpty && city.isNotEmpty) {
      return '$area, $city';
    }
    return area.isNotEmpty ? area : city;
  }

  /// Factory constructor to create a ReportModel from a Firestore document.
  factory ReportModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ReportModel(
      id: documentId,
      submittedBy: data['submittedBy'] ?? '',
      submittedByName: data['submittedByName'], // Added user's name
      submittedByPhotoUrl: data['submittedByPhotoUrl'], // Added user's photo URL
      createdAt: data['createdAt'] ?? Timestamp.now(),
      coordinates: data['coordinates'] ?? const GeoPoint(0, 0),
      // Safely cast the address map from Firestore
      address: Map<String, String?>.from(data['address'] ?? {}),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'submitted',
      category: data['category'] ?? 'uncategorized',
    );
  }

  /// Converts the ReportModel instance to a Map for storing in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'submittedBy': submittedBy,
      'submittedByName': submittedByName, // Added user's name
      'submittedByPhotoUrl': submittedByPhotoUrl, // Added user's photo URL
      'createdAt': createdAt,
      'coordinates': coordinates,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'category': category,
    };
  }
}

