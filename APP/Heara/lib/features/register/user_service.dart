import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUserWithId(String uid, UserModel user) async {
    await _db.collection('users').doc(uid).set(user.toMap());
  }
}