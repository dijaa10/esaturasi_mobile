// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // URL API
  final String baseUrl = "http://10.0.2.2:8000/api/siswa/login";

  // Metode untuk mengecek validitas token
  Future<bool> checkToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print('Token tidak ada di SharedPreferences');
        return false;
      }

      // Coba endpoint yang memerlukan autentikasi
      var response = await http.get(
        Uri.parse('$baseUrl/user'), // Sesuaikan dengan endpoint untuk cek user
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Status cek token: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Token tidak valid, coba refresh token
        return await refreshToken();
      } else {
        print('Error cek token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception saat cek token: $e');
      return false;
    }
  }

  // Metode untuk memperbarui token dengan refresh token
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        print('Refresh token tidak ditemukan');
        return false;
      }

      var response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['token'] != null) {
          await prefs.setString('token', data['token']);

          // Simpan refresh token baru jika ada
          if (data['refresh_token'] != null) {
            await prefs.setString('refresh_token', data['refresh_token']);
          }

          print('Token berhasil diperbarui');
          return true;
        }
      }

      print('Gagal refresh token: ${response.body}');
      return false;
    } catch (e) {
      print('Exception saat refresh token: $e');
      return false;
    }
  }

  // Method untuk menyimpan data user setelah login berhasil
  Future<void> saveUserData(Map<String, dynamic> data) async {
    // Kode saveUserData yang sudah ada...
  }

  // Method untuk logout
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null) {
        // Panggil endpoint logout jika ada
        try {
          await http.post(
            Uri.parse('$baseUrl/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );
        } catch (e) {
          print('Error saat logout dari server: $e');
          // Lanjutkan proses logout lokal meskipun ada error
        }
      }

      // Hapus data dari SharedPreferences
      await prefs.clear();

      return true;
    } catch (e) {
      print('Error saat logout: $e');
      return false;
    }
  }
}
