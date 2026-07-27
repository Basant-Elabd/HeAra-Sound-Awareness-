import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/audio_recording_service.dart';

/// Simple model for a sign-language word card shown on the Home screen.
class SignWord {
  final String word;
  final String? imagePath;

  SignWord({required this.word, this.imagePath});
}

class HomeController {
  // ---- Existing listening / detection state ----
  final ValueNotifier<String> statusMessage = ValueNotifier("Idle");
  final ValueNotifier<String> detectedLabel = ValueNotifier("-");
  final ValueNotifier<double> confidence = ValueNotifier(0.0);
  final ValueNotifier<bool> isListening = ValueNotifier(false);
  final ValueNotifier<bool> alertTriggered = ValueNotifier(false);

  final ValueNotifier<String> userFirstName = ValueNotifier("");

  final AudioRecordingService _audioService = AudioRecordingService();
  StreamSubscription<Map<String, dynamic>>? _resultSubscription;

  bool _isStarting = false;

  final List<SignWord> signWords = [
    SignWord(word: "Hello"),
    SignWord(word: "Thank you"),
    SignWord(word: "Yes"),
    SignWord(word: "No"),
    SignWord(word: "Help"),
    SignWord(word: "Please"),
  ];

  Future<void> init() async {
    await _loadUserName();
    _listenToServiceResults();
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        userFirstName.value = "";
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        userFirstName.value = (data?['firstName'] as String?) ?? "";
      }
    } catch (e) {
      userFirstName.value = "";
    }
  }

  /// بيسمع للنتايج الجاية من الـ Foreground Service ويحدّث الـ UI بس.
  /// الإشعار والفايبريشن موجودين جوه AudioRecordingService نفسه
  /// (في _AudioTaskHandler)، عشان يحترموا إعدادات Settings مباشرة
  /// من غير تكرار هنا.
  void _listenToServiceResults() {
    _resultSubscription =
        _audioService.resultStreamController.stream.listen((data) {
      print('🟩 [HomeController] received result: $data');

      if (data.containsKey('error')) {
        statusMessage.value = "Error: ${data['error']}";
        return;
      }

      detectedLabel.value = data['label'] ?? '-';
      confidence.value = (data['confidence'] ?? 0.0).toDouble();
      alertTriggered.value = data['alert'] ?? false;
      statusMessage.value = "Listening...";
    });
  }

  /// بدء الاستماع الفعلي: بيطلب الصلاحيات (مايك + إشعارات + تجاهل
  /// توفير البطارية) ثم يشغّل الـ Foreground Service.
  Future<bool> startListening() async {
    if (_isStarting) {
      print('🟨 [HomeController] start already in progress, ignoring tap');
      return false;
    }

    if (isListening.value) {
      print('🟨 [HomeController] already listening, ignoring tap');
      return true;
    }

    _isStarting = true;
    statusMessage.value = "Starting...";

    try {
      final hasPermission = await _audioService.requestPermissions();
      if (!hasPermission) {
        statusMessage.value = "Microphone permission denied";
        isListening.value = false;
        return false;
      }

      final started = await _audioService.start();
      if (started) {
        isListening.value = true;
        statusMessage.value = "Listening...";
      } else {
        isListening.value = false;
        statusMessage.value = "Failed to start service";
      }
      return started;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stopListening() async {
    await _audioService.stop();
    isListening.value = false;
    statusMessage.value = "Idle";
  }

  void dispose() {
    _resultSubscription?.cancel();
    statusMessage.dispose();
    detectedLabel.dispose();
    confidence.dispose();
    isListening.dispose();
    alertTriggered.dispose();
    userFirstName.dispose();
  }
}