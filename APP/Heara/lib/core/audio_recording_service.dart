import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';

import '../features/home/home_service.dart';
import 'emergency_detection_service.dart';

/// =========================================================
/// AudioRecordingService
/// =========================================================
class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final StreamController<Map<String, dynamic>> resultStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // الكولباك اللي بنسجله، محتفظين بمرجع له عشان نقدر نشيله بعدين
  void Function(Object)? _dataCallback;

  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  /// =========================
  /// طلب كل الصلاحيات المطلوبة، بما فيها المايك صريحةً
  /// =========================
  Future<bool> requestPermissions() async {
    final recorder = AudioRecorder();
    bool hasMicPermission = await recorder.hasPermission();
    print('🟦 [AudioRecordingService] mic permission: $hasMicPermission');

    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    return hasMicPermission;
  }

  void _setupTaskOptions() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'heara_listening_channel',
        channelName: 'HeAra Listening Service',
        channelDescription: 'HeAra بترصد البيئة المحيطة باستمرار',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// =========================
  /// بدء الاستماع المستمر
  /// =========================
  Future<bool> start() async {
    print('🟦 [AudioRecordingService] start() called');

    final recorder = AudioRecorder();
    final hasMicPermission = await recorder.hasPermission();
    if (!hasMicPermission) {
      print('🟥 [AudioRecordingService] cannot start - mic permission denied');
      return false;
    }

    _setupTaskOptions();

    // نسجل الكولباك قبل بدء الخدمة، ودي طريقة آمنة تتسجل
    // أكتر من مرة من غير "Stream already listened to" لأنها
    // مش مرتبطة بـ ReceivePort.listen() مباشرة.
    _registerDataCallback();

    if (await FlutterForegroundTask.isRunningService) {
      print('🟦 [AudioRecordingService] stopping stale service first');
      await FlutterForegroundTask.stopService();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('🟦 [AudioRecordingService] starting new service');
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'HeAra نشط',
      notificationText: 'بيستمع للبيئة المحيطة',
      callback: _startCallback,
    );
    final started = result is ServiceRequestSuccess;
    print('🟦 [AudioRecordingService] startService result: $started');

    return started;
  }

  Future<bool> stop() async {
    print('🟦 [AudioRecordingService] stop() called');
    final result = await FlutterForegroundTask.stopService();
    _unregisterDataCallback();
    return result is ServiceRequestSuccess;
  }

  void _registerDataCallback() {
    _unregisterDataCallback(); // نتأكد إن مفيش نسخة قديمة مسجلة قبل ما نضيف جديدة

    _dataCallback = (data) {
      print('🟩 [Main Isolate] received data from task: $data');
      if (data is Map<String, dynamic>) {
        resultStreamController.add(data);
      }
    };
    FlutterForegroundTask.addTaskDataCallback(_dataCallback!);
    print('🟦 [AudioRecordingService] data callback registered successfully');
  }

  void _unregisterDataCallback() {
    if (_dataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_dataCallback!);
      _dataCallback = null;
    }
  }

  void dispose() {
    _unregisterDataCallback();
    resultStreamController.close();
  }
}

/// =========================================================
/// ENTRY POINT
/// =========================================================
@pragma('vm:entry-point')
void _startCallback() {
  print('🟧 [Task Isolate] _startCallback() entered, setting up TaskHandler');
  FlutterForegroundTask.setTaskHandler(_AudioTaskHandler());
}

/// =========================================================
/// TASK HANDLER
/// =========================================================
class _AudioTaskHandler extends TaskHandler {
  final AudioRecorder _recorder = AudioRecorder();
  final HomeService _service = HomeService();
  final EmergencyDetectionService _emergencyService =
      EmergencyDetectionService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isBusy = false;
  bool _notificationsReady = false;

  Map<String, dynamic> _settings = {};
  String? _userId;

  // الحد الأدنى للثقة عشان يطلع إشعار/فايبريشن
  static const double _confidenceThreshold = 0.70;

  /// =========================
  /// تجهيز الإشعارات (لازم تتعمل جوه الـ Task Isolate نفسه)
  /// =========================
  Future<void> _initNotifications() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(initSettings);
      _notificationsReady = true;
    } catch (_) {
      _notificationsReady = false;
    }
  }

  /// =========================
  /// LOAD SETTINGS SAFE
  /// =========================
  Future<void> _loadSettings() async {
    try {
      _userId = FirebaseAuth.instance.currentUser?.uid;

      if (_userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(_userId)
          .collection("settings")
          .doc("prefs")
          .get();

      _settings = doc.data() ?? {};
    } catch (_) {
      _settings = {
        "notifications": true,
        "vibration": true,
        "sleepMode": false,
        "emergencyAlerts": true,
      };
    }
  }

  /// =========================
  /// SAVE LOG
  /// =========================
  Future<void> _saveLog(String sound) async {
    if (_userId == null) return;

    final now = DateTime.now();

    try {
      await FirebaseFirestore.instance
          .collection("logs")
          .doc(_userId)
          .collection("items")
          .add({
        "sound": sound,
        "date": "${now.day}/${now.month}/${now.year}",
        "time": "${now.hour}:${now.minute}",
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// بيحدد البيريوريتي: Emergency (offline) = critical دايمًا،
  /// Online مع alert=true = high، Online مع alert=false = normal
  String _resolvePriority({required String source, required bool alert}) {
    if (source == 'offline') return 'critical';
    if (alert) return 'high';
    return 'normal';
  }

  /// إشعار محلي حسب البيريوريتي (محترم لإعدادات notifications)
  Future<void> _notifyDetection({
    required String label,
    required double confidence,
    required String priority,
  }) async {
    final notificationsEnabled = _settings["notifications"] ?? true;
    if (!notificationsEnabled || !_notificationsReady) return;

    final confPercent = (confidence * 100).toStringAsFixed(0);

    final String title;
    final Importance importance;
    final Priority androidPriority;

    switch (priority) {
      case 'critical':
        title = '🚨 خطر: $label';
        importance = Importance.max;
        androidPriority = Priority.max;
        break;
      case 'high':
        title = '⚠️ تنبيه: $label';
        importance = Importance.high;
        androidPriority = Priority.high;
        break;
      default:
        title = 'تم رصد: $label';
        importance = Importance.defaultImportance;
        androidPriority = Priority.defaultPriority;
    }

    final androidDetails = AndroidNotificationDetails(
      'heara_detection_channel',
      'HeAra Sound Detection',
      channelDescription: 'إشعارات رصد الأصوات في HeAra',
      importance: importance,
      priority: androidPriority,
      enableVibration: false, // الفايبريشن متحكم فيه يدويًا بـ _vibrateForPriority
      playSound: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final id = Random().nextInt(100000);

    try {
      await _notificationsPlugin.show(
        id,
        title,
        'الثقة: $confPercent%',
        notificationDetails,
      );
    } catch (_) {}
  }

  /// VIBRATION — حسب البيريوريتي ومحترم لإعدادات vibration
  Future<void> _vibrateForPriority(String priority) async {
    try {
      final enabled = _settings["vibration"] ?? true;
      if (!enabled) return;

      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      switch (priority) {
        case 'critical':
          Vibration.vibrate(pattern: [0, 800, 300, 800, 300, 800]);
          break;
        case 'high':
          Vibration.vibrate(pattern: [0, 600, 250, 600]);
          break;
        default:
          Vibration.vibrate(duration: 500);
      }
    } catch (_) {}
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🟧 [Task Isolate] onStart() called at $timestamp');
    await _emergencyService.loadModels();
    await _initNotifications();
    await _loadSettings();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    print('🟧 [Task Isolate] onRepeatEvent() triggered at $timestamp');

    if (_isBusy) {
      print('🟨 [Task Isolate] still busy, skipping this cycle');
      return;
    }
    _isBusy = true;

    try {
      /// 🔥 Sleep Mode
      if (_settings["sleepMode"] == true) {
        _isBusy = false;
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/heara_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      print('🟧 [Task Isolate] recording to path: $path');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      await Future.delayed(const Duration(seconds: 4));
      await _recorder.stop();
      print('🟧 [Task Isolate] recording stopped');

      // =========================
      // 1) Emergency Mode (Offline)
      // =========================
      final emergencyResult = await _emergencyService.analyze(path);
      print('🟧 [Task Isolate] Emergency Mode result: $emergencyResult');

      final allowEmergency = _settings["emergencyAlerts"] ?? true;

      if (emergencyResult['status'] == 'Emergency') {
        final label = emergencyResult['type'] ?? 'Emergency';
        final conf = (emergencyResult['confidence'] ?? 0.0).toDouble();

        if (allowEmergency) {
          if (conf >= _confidenceThreshold) {
            await _notifyDetection(
              label: label,
              confidence: conf,
              priority: 'critical',
            );
            await _vibrateForPriority('critical');
          }

          FlutterForegroundTask.sendDataToMain({
            'label': label,
            'confidence': conf,
            'alert': true,
            'source': 'offline',
          });
          print('🟧 [Task Isolate] Emergency alert sent to main isolate');
        }

        await _saveLog(label);
        _isBusy = false;
        return;
      }

      // =========================
      // 2) Main Model (Online)
      // =========================
      final result = await _service.predictAudio(path);
      print('🟧 [Task Isolate] API result: $result');

      if (result != null) {
        final label = result['final_label'] ?? result['label'] ?? '---';
        final conf = (result['confidence'] ?? 0.0).toDouble();
        final alert = result['alert'] ?? false;

        if (conf >= _confidenceThreshold) {
          final priority = _resolvePriority(source: 'online', alert: alert);
          await _notifyDetection(
            label: label,
            confidence: conf,
            priority: priority,
          );
          await _vibrateForPriority(priority);
        }

        FlutterForegroundTask.sendDataToMain({
          'label': label,
          'confidence': conf,
          'alert': alert,
          'source': 'online',
        });
        print('🟧 [Task Isolate] data sent to main isolate');

        await _saveLog(label);
      } else {
        print('🟥 [Task Isolate] API result was null (request failed)');
      }
    } catch (e) {
      print('🟥 [Task Isolate] ERROR: $e');
      FlutterForegroundTask.sendDataToMain({'error': e.toString()});
    } finally {
      _isBusy = false;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('🟧 [Task Isolate] onDestroy() called');
    await _recorder.dispose();
    _emergencyService.dispose();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onReceiveData(Object data) {}
}