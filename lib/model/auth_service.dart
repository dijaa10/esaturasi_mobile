import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = "http://10.0.2.2:8000/api";
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  // Simpan token setelah login
  Future<bool> login(String nisn, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nisn': nisn, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await secureStorage.write(key: 'token', value: data['token']);
      await saveUserData(data['student']);
      return true;
    } else {
      print('Login gagal: ${response.body}');
      return false;
    }
  }

  // Ambil token yang tersimpan
  Future<String?> getToken() async {
    return await secureStorage.read(key: 'token');
  }

  Future<bool> checkToken() async {
    String? token = await getToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('$baseUrl/siswa/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return response.statusCode == 200;
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    try {
      await secureStorage.write(key: 'user_name', value: data['name']);
      await secureStorage.write(key: 'user_id', value: data['id'].toString());
    } catch (e) {
      print('Error menyimpan data user: $e');
    }
  }

  Future<bool> logout() async {
    try {
      await secureStorage.delete(key: 'token');
      await secureStorage.delete(key: 'user_name');
      await secureStorage.delete(key: 'user_id');
      return true;
    } catch (e) {
      print('Error saat logout: $e');
      return false;
    }
  }
}
