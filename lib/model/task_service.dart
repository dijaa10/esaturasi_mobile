import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class TaskService {
  final AuthService authService = AuthService();
  final String baseUrl = "http://10.0.2.2:8000/api";

  Future<bool> uploadTaskWithFile({
    required String tugasId,
    required File file,
    required String siswaId,
  }) async {
    try {
      // Ambil token dari AuthService
      String? token = await authService.getToken();
      if (token == null) {
        print('Token tidak tersedia, harus login ulang');
        return false;
      }

      var uri = Uri.parse('$baseUrl/pengumpulan-tugas');
      var request = http.MultipartRequest('POST', uri);

      // Header authorization dengan Bearer token
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Isi form fields
      request.fields['task_id'] = tugasId;

      // Cek file
      if (!file.existsSync()) {
        print('File tidak ditemukan: ${file.path}');
        return false;
      }

      // Tambah file ke request
      var multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);

      // Kirim request
      var streamedResponse = await request.send();

      // Ambil response body untuk debug
      var responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print('Upload tugas berhasil!');
        return true;
      } else if (streamedResponse.statusCode == 401) {
        print('401 Unauthorized - token expired atau tidak valid');
        return false;
      } else {
        print('Upload gagal dengan status: ${streamedResponse.statusCode}');
        print('Response: $responseBody');
        return false;
      }
    } catch (e) {
      print('Error saat upload tugas: $e');
      return false;
    }
  }
}
