import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String gender;
  final DateTime dob;
  final String hearingStatus;
  final String email;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.gender,
    required this.dob,
    required this.hearingStatus,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dob': dob.toIso8601String(),
      'hearingStatus': hearingStatus,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}