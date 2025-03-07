import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esaturasi/screen/beranda_screen.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController nisnController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  // Fungsi untuk melakukan login
  Future<void> login() async {
    const String url = 'http://127.0.0.1:8000/api/siswa/login';

    setState(() {
      _isLoading = true;
    });

    try {
      // Kirim request ke API Laravel
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nisn': nisnController.text,
          'password': passwordController.text,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Simpan token dan data siswa ke SharedPreferences
          await saveUserData(data);

          // Navigasi ke halaman beranda
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Beranda()),
          );
        } else {
          // Tampilkan pesan error dari API
          showErrorSnackbar(data['message'] ?? 'Login gagal');
        }
      } else if (response.statusCode == 401) {
        showErrorSnackbar('NISN atau password salah');
      } else {
        // Tampilkan error umum
        showErrorSnackbar('Gagal menghubungi server (${response.statusCode})');
      }
    } catch (e) {
      print("Error during login: $e");
      showErrorSnackbar('Terjadi kesalahan. Periksa koneksi internet Anda!');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Menyimpan data user setelah login berhasil
  Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan token autentikasi
    if (data['token'] != null) {
      await prefs.setString('token', data['token']);
    }

    // Simpan data siswa
    if (data['siswa'] != null) {
      await prefs.setString('siswa_id', data['siswa']['id'].toString());
      await prefs.setString('nisn', data['siswa']['nisn']);
      await prefs.setString('nama', data['siswa']['nama']);
      await prefs.setString('email', data['siswa']['email']);
      if (data['siswa']['foto_profil'] != null) {
        prefs.setString('foto_profil', data['siswa']['foto_profil']);
      } else {
        prefs.setString('foto_profil', "https://via.placeholder.com/150");
      }

      await prefs.setString('kelas_id', data['siswa']['kelas_id'].toString());
      await prefs.setString(
          'jurusan_id', data['siswa']['jurusan_id'].toString());
      print('Foto Profil: ${data['siswa']['foto_profil']}');
    }

    // Set status login
    await prefs.setBool('isLoggedIn', true);
  }

  // Menampilkan pesan error
  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Toggle visibility password
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Login Siswa",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset('assets/images/logo.png', width: 250, height: 200),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2446CE),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: nisnController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.person, color: Colors.black54),
                          hintText: 'Masukkan NISN',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.lock, color: Colors.black54),
                          suffixIcon: GestureDetector(
                            onTap: _togglePasswordVisibility,
                            child: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black54,
                            ),
                          ),
                          hintText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Tambahkan fungsi lupa password di sini
                          },
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C9EDB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
