import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login.dart'; // Sesuaikan dengan path login Anda

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

  // Fungsi Logout
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(fotoProfil),
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
                    onPressed: () {},
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
                      _logout(context);
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
