import 'dart:async';
import 'dart:io';
import 'package:sih_crowd_source/src/data/models/user_model.dart';
import 'package:sih_crowd_source/src/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AuthState { loading, unauthenticated, authenticated_profile_loading, authenticated_profile_loaded }

class AuthStateProvider with ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  AuthState _authState = AuthState.loading;
  late StreamSubscription<User?> _authStreamSub;
  UserModel? _userModel;

  AuthStateProvider() {
    _authStreamSub = _repo.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthState get authState => _authState;
  UserModel? get user => _userModel;

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _authState = AuthState.unauthenticated;
      _userModel = null;
    } else {
      _authState = AuthState.authenticated_profile_loading;
      notifyListeners(); 
      
      _userModel = await _repo.getUserDetails(user.uid);
      
      // ====================== THE DEFINITIVE FIX ======================
      if (_userModel == null) {
        print("CRITICAL ERROR: User is authenticated but no profile found in Firestore. Forcing logout.");
        await signOut();
        return; 
      }
      _authState = AuthState.authenticated_profile_loaded;
      // =============================================================
    }
    notifyListeners();
  }
  
  Future<String?> signIn(String email, String password) async {
    return await _repo.signInWithEmailAndPassword(email, password);
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    File? profileImage,
  }) async {
    return await _repo.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<String?> updateProfile({
    String? displayName,
    File? newProfileImage,
  }) async {
    if (_userModel == null) return "No user is currently logged in.";

    final error = await _repo.updateUserProfile(
      uid: _userModel!.uid,
      displayName: displayName,
      newProfileImage: newProfileImage,
    );

    if (error == null) {
      _userModel = await _repo.getUserDetails(_userModel!.uid);
      notifyListeners();
    }
    return error;
  }

  Future<String?> deleteAccount() async {
    final error = await _repo.deleteUserAccount();
    // The authStateChanges stream will automatically handle logout on success.
    return error;
  }

  @override
  void dispose() {
    _authStreamSub.cancel();
    super.dispose();
  }
}

