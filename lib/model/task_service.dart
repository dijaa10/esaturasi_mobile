import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class TaskService {
  // Metode untuk mendapatkan token yang valid
  Future<String?> getValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      print('Token yang disimpan: $token');

      if (token == null) {
        print('Token tidak ditemukan, user belum login.');
        return null;
      }

      return token;
    } catch (e) {
      print('Error saat mendapatkan token: $e');
      return null;
    }
  }

  // Metode upload file dengan penanganan tipe data yang benar
  Future<bool> uploadTaskWithFile({
    required String tugasId,
    required File file,
    required String siswaId,
  }) async {
    try {
      // Dapatkan token yang valid
      String? token = await getValidToken();

      if (token == null) {
        print('Tidak bisa mendapatkan token yang valid.');
        return false;
      }

      // Gunakan URI yang benar untuk API endpoint
      var uri = Uri.parse('http://10.0.2.2:8000/api/pengumpulan-tugas');

      // Buat request multipart
      var request = http.MultipartRequest('POST', uri);

      // Tambahkan header yang diperlukan
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Pastikan tugas_id dan siswa_id adalah angka integer
      // Parse string menjadi int lalu kembali ke string untuk memastikan format yang benar
      int tugasIdInt;
      int siswaIdInt;

      try {
        tugasIdInt = int.parse(tugasId);
        siswaIdInt = int.parse(siswaId);
      } catch (e) {
        print('Error konversi ID: $e');
        print('tugas_id: $tugasId, siswa_id: $siswaId');
        return false;
      }

      // Tambahkan field dengan format yang benar - setelah konversi ke int
      request.fields['tugas_id'] = tugasIdInt.toString();
      request.fields['siswa_id'] = siswaIdInt.toString();

      // Log data yang akan dikirim untuk debugging
      print('Mengirim data: tugas_id=${tugasIdInt}, siswa_id=${siswaIdInt}');

      // Tambahkan file
      var fileStream = await http.MultipartFile.fromPath('file', file.path);
      print(
          'File yang akan diunggah: ${file.path}, ukuran: ${await file.length()} bytes');
      request.files.add(fileStream);

      // Kirim request
      print('Mengirim request ke ${uri.toString()}');
      var streamedResponse =
          await request.send().timeout(Duration(seconds: 30));

      // Proses respons
      var responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print('Upload sukses dengan status: ${streamedResponse.statusCode}');
        print('Respons: $responseBody');
        return true;
      } else {
        print('Upload gagal: ${streamedResponse.statusCode}, $responseBody');

        // Analisis kesalahan validasi
        if (streamedResponse.statusCode == 422) {
          try {
            var errorData = jsonDecode(responseBody);
            if (errorData['errors'] != null) {
              print('Detail validasi error:');
              errorData['errors'].forEach((field, errors) {
                print('- $field: ${errors.join(", ")}');
              });
            }
          } catch (e) {
            print('Tidak dapat parse detail error: $e');
          }
        } else if (streamedResponse.statusCode == 401) {
          print('Token tidak valid atau expired, perlu login ulang.');
          // Arahkan ke halaman login jika token expired
          // Misalnya, arahkan pengguna ke login page
        }

        return false;
      }
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
