import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sih_crowd_source/src/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Stream to notify the app of authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Gets the currently signed-in Firebase user.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in a user with their email and password.
  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  /// Creates a new user account and saves their details to Firestore.
  /// Includes rollback on failure and email verification.
  Future<String?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    File? profileImage,
  }) async {
    UserCredential? userCredential;
    try {
      // 1. Create user in Firebase Auth
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        String? photoURL;
        // 2. Upload profile image if provided
        if (profileImage != null) {
          photoURL = await _uploadProfileImage(profileImage, user.uid);
        }

        // 3. Create UserModel
        final newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          photoURL: photoURL,
          createdAt: Timestamp.now(),
        );

        // 4. Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // 5. Send verification email
        if (!user.emailVerified) {
          await sendVerificationEmail(userCredential.user!);
        }
      }
    } catch (e) {
      if (userCredential != null) {
        await userCredential.user?.delete();
      }
      throw Exception("Registration failed: $e");
    }
  }

  /// 🔹 Send email verification
  Future<void> sendVerificationEmail(User user) async {
    if (!user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        throw Exception("Failed to send verification email: $e");
      }
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Fetches the detailed UserModel from Firestore for a given user ID.
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  /// Updates user profile details in Firestore and Firebase Auth.
  Future<String?> updateUserProfile({
    required String uid,
    String? displayName,
    File? newProfileImage,
  }) async {
    try {
      String? photoURL;
      Map<String, dynamic> dataToUpdate = {};

      if (newProfileImage != null) {
        photoURL = await _uploadProfileImage(newProfileImage, uid);
        dataToUpdate['photoURL'] = photoURL;
      }
      if (displayName != null) {
        dataToUpdate['displayName'] = displayName;
      }

      if (dataToUpdate.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(dataToUpdate);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Helper method to upload a profile image to Firebase Storage.
  Future<String?> _uploadProfileImage(File imageFile, String uid) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> deleteUserAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception("No user is currently signed in.");
      }
      final uid = user.uid;

      // 1. Delete profile image from Storage (if it exists)
      final imageRef = _storage.ref().child('profile_images/$uid.jpg');
      try {
        await imageRef.delete();
      } catch (e) {
        // This is not a critical error if the file doesn't exist.
        print("Info: Could not delete profile image (it may not exist): $e");
      }

      // 2. Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // 3. Delete the user from Firebase Authentication
      // This is the final step and requires recent login for security.
      // For this app, we proceed directly. In a production app with sensitive
      // data, you would force the user to re-authenticate first.
      await user.delete();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      // Handle specific auth errors, e.g., 'requires-recent-login'
      return 'Deletion failed: ${e.message}';
    } catch (e) {
      return 'An unexpected error occurred during account deletion.';
    }
  }
}
