import 'package:esaturasi/login.dart';
import 'package:flutter/material.dart';
import 'login.dart'; // Ganti dengan path yang sesuai

class ProfileScreen extends StatelessWidget {
  final String nama = "Chodijah";
  final String email = "chodijah@email.com";
  final String namaKelas = "XI RPL 1";
  final String namaJurusan = "Rekayasa Perangkat Lunak";
  final String fotoProfil =
      "https://via.placeholder.com/150"; // Ganti dengan URL foto asli

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profil Saya",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Aksi Edit Profil
                    },
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
                  _buildInfoCard(Icons.phone, "Nomor HP", "+62 852-0485-2440"),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  // 🔹 Fungsi Logout
  void _logout(BuildContext context) {
    // Hapus session atau token jika ada
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }
}
