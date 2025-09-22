import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart'; // Ensure this path is correct

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fetches reports and correctly uses the updated fromMap factory.
  Future<List<ReportModel>> fetchUserReports(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reports')
          .where('submittedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return ReportModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error getting reports for user: $e');
      rethrow;
    }
  }
  
  /// Adds a report and correctly uses the updated toMap method.
  Future<void> addReport(ReportModel report, File imageFile) async {
    try {
      final docRef = await _firestore.collection('reports').add(report.toMap());
      
      final imageUrl = await _uploadImage(imageFile, docRef.id);
      if (imageUrl != null) {
        // The field in Firestore should be 'imageUrl' to match the model
        await docRef.update({'imageUrl': imageUrl});
      }
    } catch (e) {
      print('Error adding report: $e');
      rethrow;
    }
  }

  Future<String?> _uploadImage(File imageFile, String reportId) async {
    try {
      final ref = _storage.ref().child('reports/$reportId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<ReportModel?> fetchLatestReport(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reports')
          .where('submittedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1) // We only want the most recent one
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ReportModel.fromMap(doc.data(), doc.id);
      }
      // Return null if the user has no reports
      return null; 
    } catch (e) {
      print('Error fetching latest report: $e');
      rethrow; // Rethrow to be handled by the provider/UI
    }
  }
}


