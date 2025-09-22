import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sih_crowd_source/src/data/models/report_model.dart';
import 'package:sih_crowd_source/src/data/repositories/report_repository.dart';

class ReportProvider with ChangeNotifier {
  final ReportRepository _repo = ReportRepository();

  Future<String?> submitReport(ReportModel report, File imageFile) async {
    try {
      await _repo.addReport(report, imageFile);
      return null; 
    } catch (e) {
      print('Error in submitReport provider: $e');
      return e.toString();
    }
  }

  Future<List<ReportModel>> fetchMyReports(String userId) async {
    try {
      return await _repo.fetchUserReports(userId);
    } catch (e) {
      print('Error in fetchMyReports provider: $e');
      rethrow;
    }
  }

  Future<ReportModel?> getLatestReport(String userId) async {
    try {
      return await _repo.fetchLatestReport(userId);
    } catch (e) {
      print('Error getting latest report in provider: $e');
      rethrow;
    }
  }
  
}

