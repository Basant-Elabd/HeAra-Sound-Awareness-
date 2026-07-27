import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/register/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------
  // 🔥 REGISTER
  // -------------------------
  Future<String> registerUser({
    required UserModel user,
    required String password,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      final String uid = result.user!.uid;

      // 2. Save user data in Firestore (with UID)
      await _db.collection('users').doc(uid).set({
        ...user.toMap(),
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // -------------------------
  // 🔐 LOGIN
  // -------------------------
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return "success";
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return "Something went wrong";
    }
  }

  // -------------------------
  // ❌ ERROR HANDLING
  // -------------------------
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      // Register errors
      case 'email-already-in-use':
        return "Email already exists";
      case 'invalid-email':
        return "Invalid email format";
      case 'weak-password':
        return "Weak password (min 6 chars)";

      // Login errors
      case 'user-not-found':
        return "No user found with this email";
      case 'wrong-password':
        return "Wrong password";
      case 'user-disabled':
        return "This account is disabled";

      default:
        return "Authentication error";
    }
  }
}