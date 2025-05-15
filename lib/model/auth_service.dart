import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class AuthService {
  final String baseUrl = "http://10.0.2.2:8000/api";
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  Future<String?> getValidToken() async {
    try {
      String? token = await secureStorage.read(key: 'token');
      print('Token yang disimpan: $token');
      return token;
    } catch (e) {
      print('Error saat mendapatkan token: $e');
      return null;
    }
  }

  Future<bool> checkToken({bool allowRetry = true}) async {
    try {
      String? token = await secureStorage.read(key: 'token');
      if (token == null) {
        print('Token tidak ada di secure storage');
        return false;
      }

      var response = await http.get(
        Uri.parse('$baseUrl/siswa/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Status cek token: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 && allowRetry) {
        print('Token tidak valid, mencoba refresh token...');
        return await refreshToken();
      } else {
        print('Token cek error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception saat cek token: $e');
      return false;
    }
  }

  bool _isRefreshing = false;
  Future<bool> refreshToken() async {
    // Mencegah multiple refresh secara bersamaan
    if (_isRefreshing) {
      print('Refresh token sedang berjalan, tunggu...');
      await Future.delayed(Duration(milliseconds: 500));
      return await checkToken(allowRetry: false);
    }

    _isRefreshing = true;

    try {
      String? refreshToken = await secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('Refresh token tidak ditemukan');
        _isRefreshing = false;
        return false;
      }

      print(
          'Mengirim refresh request dengan refresh token: ${refreshToken.substring(0, min(10, refreshToken.length))}...');

      var response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      print('Respons refresh token status: ${response.statusCode}');
      print('Respons refresh token body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Sesuaikan dengan format respons API Anda
        if (data['token'] != null) {
          // Simpan token baru
          await secureStorage.write(key: 'token', value: data['token']);
          print('Token berhasil disimpan');

          // Verifikasi token baru
          _isRefreshing = false;
          return await checkToken(allowRetry: false);
        } else {
          print('Data token tidak ditemukan dalam respons: $data');
          _isRefreshing = false;
          return false;
        }
      } else {
        print('Gagal refresh token: ${response.statusCode}, ${response.body}');
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      print('Exception saat refresh token: $e');
      _isRefreshing = false;
      return false;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    try {
      await secureStorage.write(key: 'user_name', value: data['name']);
      await secureStorage.write(key: 'user_id', value: data['id'].toString());
      print('Data user berhasil disimpan');
    } catch (e) {
      print('Error saat menyimpan data user: $e');
    }
  }

  Future<bool> logout() async {
    try {
      await secureStorage.delete(key: 'token');
      await secureStorage.delete(key: 'refresh_token');
      await secureStorage.delete(key: 'user_name');
      await secureStorage.delete(key: 'user_id');
      print('Logout berhasil');
      return true;
    } catch (e) {
      print('Error saat logout: $e');
      return false;
    }
  }
}
