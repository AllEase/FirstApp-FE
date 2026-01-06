import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return http.get(
      Uri.parse(url),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> postWithNoToken(
    String url,
    Map<String, dynamic> body,
  ) async {
    return http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.StreamedResponse> multipartPost({
    required String url,
    required Map<String, String> fields,
    required List<File> images,
    String imageFieldName = 'images',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final request = http.MultipartRequest('POST', Uri.parse(url));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    for (final image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(imageFieldName, image.path),
      );
    }
    return await request.send();
  }
}
