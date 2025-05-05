import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';

class TaskService {
  Future<bool> uploadTaskWithFile(
      {required String tugasId,
      required File file,
      required String siswaId}) async {
    try {
      var uri = Uri.parse('http://10.0.2.2:8000/api/pengumpulan-tugas');
      var request = http.MultipartRequest('POST', uri);

      // Menambahkan header (bisa ditambah token jika diperlukan)
      // request.headers['Authorization'] = 'Bearer <Your_Token>';

      // Menambahkan field ke dalam form data
      request.fields['tugas_id'] = tugasId;
      request.fields['siswa_id'] = siswaId;

      // Menambahkan file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Set timeout untuk permintaan HTTP
      var response = await request.send().timeout(Duration(seconds: 30));

      // Menunggu hasil dari request dan memeriksa status
      if (response.statusCode == 201) {
        print('Upload sukses!');
        return true;
      } else {
        var responseBody = await response.stream.bytesToString();
        print('Upload gagal: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      // Menangani kesalahan dengan lebih spesifik
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
