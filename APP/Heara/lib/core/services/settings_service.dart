import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return _defaultSettings();
      }

      final doc = await _db
          .collection("users")
          .doc(user.uid)
          .collection("settings")
          .doc("prefs")
          .get();

      if (!doc.exists || doc.data() == null) {
        return _defaultSettings();
      }

      return doc.data()!;
    } catch (e) {
      return _defaultSettings();
    }
  }

  /// بيحفظ إعداد واحد بس، من غير ما يمسح باقي الإعدادات
  /// (merge: true بتضمن ده)
  Future<void> saveSetting(String key, bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _db
          .collection("users")
          .doc(user.uid)
          .collection("settings")
          .doc("prefs")
          .set({key: value}, SetOptions(merge: true));
    } catch (e) {
      print('🟥 [SettingsService] failed to save $key: $e');
    }
  }

  Map<String, dynamic> _defaultSettings() {
    return {
      "notifications": true,
      "vibration": true,
      "sleepMode": false,
      "emergencyAlerts": true,
    };
  }
}