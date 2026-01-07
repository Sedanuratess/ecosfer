import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Backend URL - Render.com (Production)
  static const String baseUrl = 'https://ecoscan-api-x1w8.onrender.com';
  
  // Eski yerel adresler (Referans için):
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Emülatör

  // Gerçek cihaz için localhost kullanın:
  // static const String baseUrl = 'http://localhost:8000';

  // PC IP'niz ile de test edebilirsiniz:
  // static const String baseUrl = 'http://192.168.1.XXX:8000';

  /// Görseli backend'e gönder ve analiz et
  Future<Map<String, dynamic>?> analyzeWaste(File imageFile) async {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/analyze'),
      );

      // Dosya uzantısını al
      String fileName = imageFile.path.split('/').last;

      // MIME type'ı belirle
      MediaType contentType = MediaType('image', 'jpeg');
      if (fileName.toLowerCase().endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        contentType = MediaType('image', 'webp');
      }

      // Dosyayı ekle - contentType'ı açıkça belirt
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: fileName,
          contentType: contentType,
        ),
      );

      print('📤 Gönderiliyor: $fileName (${contentType.mimeType})');

    // Backend'e gönder (Render cold start için 120sn timeout)
      var streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Yanıt: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('✅ Başarılı: $jsonResponse');
        return jsonResponse;
      } else {
        print('❌ Hata: ${response.statusCode} - ${response.body}');
        throw Exception('Sunucu Hatası: ${response.statusCode}');
      }
  }

  /// Backend sağlık kontrolü
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check hatası: $e');
      return false;
    }
  }

  /// Atık türlerini getir
  Future<Map<String, dynamic>?> getWasteTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/waste-types'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Waste types hatası: $e');
      return null;
    }
  }
}
