import 'package:http/http.dart' as http;
import 'dart:io';

class TaskService {
  // Upload tugas ke server
  Future<bool> uploadTask(String filePath) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://127.0.0.1:8000/api/pengumpulan-tugas'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();

      if (response.statusCode == 200) {
        return true; // Pengunggahan berhasil
      }
    } catch (e) {
      print('Error uploading task: $e');
    }
    return false; // Pengunggahan gagal
  }
}
