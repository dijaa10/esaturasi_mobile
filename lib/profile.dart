import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'login.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String nama = "";
  String email = "";
  String namaKelas = "Memuat...";
  String namaJurusan = "Memuat...";
  String fotoProfil = "";
  final String baseUrl = "http://127.0.0.1:8000/";
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // untuk mengambil data dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nama = prefs.getString('nama') ?? "Nama Tidak Ditemukan";
      email = prefs.getString('email') ?? "Belum tersedia";
      String fotoPath = prefs.getString('foto_profil') ?? "";
      fotoProfil = fotoPath.isNotEmpty
          ? "${baseUrl}storage/$fotoPath"
          : "https://via.placeholder.com/150";
    });

    // Ambil nama kelas dan jurusan berdasarkan ID
    String? idKelas = prefs.getString('kelas_id');
    String? idJurusan = prefs.getString('jurusan_id');

    if (idKelas != null) _fetchKelas(idKelas);
    if (idJurusan != null) _fetchJurusan(idJurusan);
  }

  // untuk mengambil nama kelas dari API
  Future<void> _fetchKelas(String idKelas) async {
    try {
      final response =
          await http.get(Uri.parse("${baseUrl}api/get-kelas/$idKelas"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaKelas = data['nama_kelas'] ?? "Kelas Tidak Ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        namaKelas = "Gagal Memuat Kelas";
      });
    }
  }

  // untuk mengambil nama jurusan dari API
  Future<void> _fetchJurusan(String idJurusan) async {
    try {
      final response =
          await http.get(Uri.parse("${baseUrl}api/get-jurusan/$idJurusan"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaJurusan = data['nama_jurusan'] ?? "Jurusan Tidak Ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        namaJurusan = "Gagal Memuat Jurusan";
      });
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Dialog tidak bisa ditutup dengan klik di luar
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[700]),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Ya, Keluar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                _logout(context); // Lakukan logout
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi Logout
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  // Fungsi untuk memilih foto dari galeri
  Future<void> _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _uploadImage(File(image.path));
    }
  }

  // Fungsi untuk mengambil foto dengan kamera
  Future<void> _getImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _uploadImage(File(photo.path));
    }
  }

  // Fungsi untuk menghapus foto profil
  Future<void> _deleteProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('api_token');

      final response = await http.delete(
        Uri.parse("${baseUrl}api/delete-profile-photo"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          fotoProfil = "https://via.placeholder.com/150";
        });

        // Update SharedPreferences
        await prefs.setString('foto_profil', "");

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Foto profil berhasil dihapus')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus foto profil')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  // Fungsi untuk upload gambar ke server
  Future<void> _uploadImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('api_token');

      // Membuat request multipart
      var request = http.MultipartRequest(
          'POST', Uri.parse("${baseUrl}api/update-profile-photo"));

      // Menambahkan header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Menambahkan file gambar
      request.files.add(
          await http.MultipartFile.fromPath('foto_profil', imageFile.path));

      // Mengirim request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fotoProfil = data['foto_url'] ?? fotoProfil;
        });

        // Update SharedPreferences
        await prefs.setString('foto_profil', data['foto_path'] ?? "");

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Foto profil berhasil diperbarui')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui foto profil')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  // Menampilkan popup seperti Instagram
  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildOptionItem(
                icon: Icons.photo_library,
                text: 'Pilih dari Galeri',
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromGallery();
                },
              ),
              _buildOptionItem(
                icon: Icons.camera_alt,
                text: 'Ambil Foto',
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromCamera();
                },
              ),
              _buildOptionItem(
                icon: Icons.delete,
                text: 'Hapus Foto',
                isDelete: true,
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePhoto();
                },
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Batal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk item opsi
  Widget _buildOptionItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDelete ? Colors.red : Colors.blue,
              size: 24,
            ),
            SizedBox(width: 15),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isDelete ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      appBar: AppBar(
        title: Text("Profil Saya",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Header Profile
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showProfilePhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(fotoProfil),
                          backgroundColor: Colors.grey[300],
                          onBackgroundImageError: (exception, stackTrace) {
                            print("Error loading image: $exception");
                            print("Image URL was: $fotoProfil");
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    nama,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showProfilePhotoOptions,
                    icon: Icon(Icons.edit),
                    label: Text("Edit Profil"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Informasi Detail
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard(Icons.school, "Kelas", namaKelas),
                  _buildInfoCard(Icons.book, "Jurusan", namaJurusan),
                  _buildInfoCard(Icons.email, "Email", email),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showLogoutConfirmationDialog(context);
                    },
                    icon: Icon(Icons.logout),
                    label: Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Fungsi untuk Card Info
  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
