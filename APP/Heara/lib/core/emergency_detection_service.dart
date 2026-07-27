import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

/// =========================================================
/// EmergencyDetectionService
/// =========================================================
/// خدمة الكشف عن الأصوات الطارئة (Offline، on-device بالكامل).
/// بتاخد ملف WAV، تستخرج الصوت الخام (raw audio samples)،
/// وتشغل موديلين TFLite بالترتيب:
///   1. Emergency Model: هل الصوت "طارئ"؟
///   2. Type Model: لو طارئ، أي نوع (Siren/Gunshot/Cracking)؟
/// =========================================================
class EmergencyDetectionService {
  static final EmergencyDetectionService _instance =
      EmergencyDetectionService._internal();
  factory EmergencyDetectionService() => _instance;
  EmergencyDetectionService._internal();

  Interpreter? _emergencyInterpreter;
  Interpreter? _typeInterpreter;

  static const int sampleRate = 16000;
  static const int durationSeconds = 3;
  static const int targetLen = sampleRate * durationSeconds; // 48000
  static const double threshold = 0.3;

  static const List<String> typeLabels = ['Cracking', 'Gunshot', 'Siren'];
  // ترتيب الـ labels لازم يطابق بالضبط ترتيب LabelEncoder.classes_ في Python
  // (alphabetical: Cracking, Gunshot, Siren)

  bool _isLoaded = false;

  /// =========================
  /// تحميل الموديلين (مرة واحدة بس)
  /// =========================
  Future<void> loadModels() async {
    if (_isLoaded) return;

    try {
      _emergencyInterpreter = await Interpreter.fromAsset(
        'assets/models/emergency_model_raw.tflite',
      );
      _typeInterpreter = await Interpreter.fromAsset(
        'assets/models/type_model_raw.tflite',
      );
      _isLoaded = true;
      print('🟢 [EmergencyDetectionService] Models loaded successfully');
    } catch (e) {
      print('🟥 [EmergencyDetectionService] Failed to load models: $e');
    }
  }

  /// =========================
  /// قراءة ملف WAV واستخراج الصوت الخام (PCM 16-bit)
  /// =========================
  List<double> _readWavSamples(String filePath) {
    final bytes = File(filePath).readAsBytesSync();

    // WAV header قياسي = 44 بايت
    const headerSize = 44;
    if (bytes.length <= headerSize) return [];

    final pcmBytes = bytes.sublist(headerSize);
    final byteData = ByteData.sublistView(pcmBytes);

    final sampleCount = pcmBytes.length ~/ 2; // 16-bit = 2 bytes per sample
    final samples = List<double>.filled(sampleCount, 0.0);

    for (int i = 0; i < sampleCount; i++) {
      final intSample = byteData.getInt16(i * 2, Endian.little);
      samples[i] = intSample / 32768.0; // تحويل لـ float بين -1 و 1
    }

    return samples;
  }

  /// =========================
  /// توحيد الطول (padding أو قطع) + normalize
  /// =========================
  Float32List _preprocessAudio(List<double> rawSamples) {
    List<double> audio;

    if (rawSamples.length < targetLen) {
      audio = List<double>.filled(targetLen, 0.0);
      for (int i = 0; i < rawSamples.length; i++) {
        audio[i] = rawSamples[i];
      }
    } else {
      audio = rawSamples.sublist(0, targetLen);
    }

    // normalize: audio / max(abs(audio))  -- نفس منطق Python بالضبط
    double maxVal = 0.0;
    for (final v in audio) {
      final absV = v.abs();
      if (absV > maxVal) maxVal = absV;
    }
    if (maxVal == 0) maxVal = 1e-9;

    final normalized = Float32List(targetLen);
    for (int i = 0; i < targetLen; i++) {
      normalized[i] = audio[i] / maxVal;
    }

    return normalized;
  }

  /// =========================
  /// التحليل الكامل: من ملف WAV لنتيجة نهائية
  /// =========================
  Future<Map<String, dynamic>> analyze(String wavFilePath) async {
    if (!_isLoaded) {
      await loadModels();
    }

    if (_emergencyInterpreter == null || _typeInterpreter == null) {
      return {"status": "error", "message": "Models not loaded"};
    }

    try {
      final rawSamples = _readWavSamples(wavFilePath);
      final processedAudio = _preprocessAudio(rawSamples);

      // Reshape لـ (1, targetLen, 1)
      final input = processedAudio.reshape([1, targetLen, 1]);

      // =========================
      // EMERGENCY MODEL
      // =========================
      final emergencyOutput = List.filled(1 * 1, 0.0).reshape([1, 1]);
      _emergencyInterpreter!.run(input, emergencyOutput);

      final emergencyProb = emergencyOutput[0][0] as double;
      print('🟦 [EmergencyDetectionService] Emergency probability: $emergencyProb');

      if (emergencyProb < threshold) {
        return {"status": "Normal", "type": null};
      }

      // =========================
      // TYPE MODEL
      // =========================
      final typeOutput =
          List.filled(1 * typeLabels.length, 0.0).reshape([1, typeLabels.length]);
      _typeInterpreter!.run(input, typeOutput);

      final probs = typeOutput[0] as List<double>;
      int maxIndex = 0;
      double maxProb = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIndex = i;
        }
      }

      return {
        "status": "Emergency",
        "type": typeLabels[maxIndex],
        "confidence": maxProb,
      };
    } catch (e) {
      print('🟥 [EmergencyDetectionService] Error during analysis: $e');
      return {"status": "error", "message": e.toString()};
    }
  }

  void dispose() {
    _emergencyInterpreter?.close();
    _typeInterpreter?.close();
    _isLoaded = false;
  }
}