import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeService {
  final String _baseUrl = 'http://10.202.100.141:8000';

  Future<Map<String, dynamic>?> predictAudio(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 45),
      );

      final body = await response.stream.bytesToString();
      print('🟪 [HomeService] response status: ${response.statusCode}');
      print('🟪 [HomeService] response body: $body');
      return jsonDecode(body);

    } catch (e) {
      print('🟥 [HomeService] REAL ERROR: $e');
      return null;
    }
  }

  /// =========================
  /// Custom Sounds - تسجيل صوت جديد
  /// =========================
  Future<Map<String, dynamic>?> registerCustomSound({
    required String filePath,
    required String userId,
    required String label,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/custom/register'),
      );

      request.fields['user_id'] = userId;
      request.fields['label'] = label;
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 45),
      );

      final body = await response.stream.bytesToString();
      print('🟪 [HomeService] register response: $body');
      return jsonDecode(body);

    } catch (e) {
      print('🟥 [HomeService] register ERROR: $e');
      return null;
    }
  }

  /// =========================
  /// Custom Sounds - التنبؤ
  /// =========================
  Future<Map<String, dynamic>?> predictCustomSound({
    required String filePath,
    required String userId,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/custom/predict'),
      );

      request.fields['user_id'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 45),
      );

      final body = await response.stream.bytesToString();
      print('🟪 [HomeService] custom predict response: $body');
      return jsonDecode(body);

    } catch (e) {
      print('🟥 [HomeService] custom predict ERROR: $e');
      return null;
    }
  }
}