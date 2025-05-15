import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'auth_service.dart';

class TaskService {
  final AuthService authService = AuthService();
  final String baseUrl = "http://10.0.2.2:8000/api";

  Future<bool> uploadTaskWithFile({
    required String tugasId,
    required File file,
    required String siswaId,
    int retry = 2, // Tingkatkan batas retry menjadi 2
  }) async {
    try {
      // Dapatkan token valid
      String? token = await authService.getValidToken();
      if (token == null) {
        print('Tidak dapat mendapatkan token valid untuk upload');
        return false;
      }

      // Log untuk debugging
      print(
          'Menggunakan token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');

      var uri = Uri.parse('$baseUrl/pengumpulan-tugas');
      var request = http.MultipartRequest('POST', uri);

      // Pastikan format header benar
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Debug header
      print('Headers request: ${request.headers}');

      // Konversi ID
      int tugasIdInt;
      int siswaIdInt;
      try {
        tugasIdInt = int.parse(tugasId);
        siswaIdInt = int.parse(siswaId);
      } catch (e) {
        print('Error konversi ID: $e');
        return false;
      }

      request.fields['tugas_id'] = tugasIdInt.toString();
      request.fields['siswa_id'] = siswaIdInt.toString();

      // Debug fields
      print('Fields request: ${request.fields}');

      // Cek file
      if (file.existsSync()) {
        var fileStream = await http.MultipartFile.fromPath('file', file.path);
        request.files.add(fileStream);
        print('File yang diunggah: ${file.path}');
        print('File size: ${await file.length()} bytes');
      } else {
        print('File tidak ditemukan: ${file.path}');
        return false;
      }

      print('Mengirim request ke ${uri.toString()}');

      // Gunakan timeout yang lebih panjang untuk file besar
      var streamedResponse =
          await request.send().timeout(Duration(seconds: 60));

      // Log response code segera
      print('Response status code: ${streamedResponse.statusCode}');

      // Ambil response body
      var responseBytes = await streamedResponse.stream.toBytes();
      var responseBody = utf8.decode(responseBytes);

      // Log full response untuk debugging
      print('Response headers: ${streamedResponse.headers}');
      print('Response body: $responseBody');

      // Handle responses
      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print('Upload sukses!');
        return true;
      } else if (streamedResponse.statusCode == 401 && retry > 0) {
        print('401: Token expired, mencoba refresh dan upload ulang...');

        // Tunggu sebentar sebelum refresh
        await Future.delayed(Duration(milliseconds: 500));

        bool refreshed = await authService.refreshToken();
        if (refreshed) {
          // Berikan delay sebelum mencoba upload ulang
          await Future.delayed(Duration(seconds: 1));

          return await uploadTaskWithFile(
            tugasId: tugasId,
            file: file,
            siswaId: siswaId,
            retry: retry - 1,
          );
        } else {
          print('Refresh gagal, tidak dapat melanjutkan upload.');
          return false;
        }
      } else if (streamedResponse.statusCode == 429) {
        print('429: Too Many Attempts - tunggu beberapa saat.');
        if (retry > 0) {
          // Tunggu lebih lama untuk rate limit
          await Future.delayed(Duration(seconds: 5));
          return await uploadTaskWithFile(
            tugasId: tugasId,
            file: file,
            siswaId: siswaId,
            retry: retry - 1,
          );
        }
      } else {
        // Coba parse respons JSON untuk informasi error yang lebih detail
        try {
          var jsonResponse = jsonDecode(responseBody);
          print('Error details: $jsonResponse');
        } catch (e) {
          // Jika tidak bisa di-parse sebagai JSON, gunakan respons mentah
        }
      }

      print('Upload gagal: ${streamedResponse.statusCode}, $responseBody');
      return false;
    } catch (e) {
      if (e is SocketException) {
        print('Tidak ada koneksi internet: $e');
      } else if (e is TimeoutException) {
        print('Permintaan timeout: $e');
      } else {
        print('Exception saat upload: $e');
      }
      return false;
    }
  }
}
