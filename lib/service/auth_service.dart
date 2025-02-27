import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:esaturasi/model/siswa.dart';

class AuthService {
  Future<Siswa?> login(String email, String password) async {
    final url = Uri.parse("https://api.example.com/login");

    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return Siswa.fromJson(data['siswa']); // Parse ke model
        } else {
          print("Login gagal: ${data['message']}");
          return null;
        }
      } else {
        print("Error Server: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
}
