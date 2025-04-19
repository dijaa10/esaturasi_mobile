import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  Map<String, dynamic> profileData = {};
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        setState(() {
          errorMessage = 'Token tidak ditemukan. Silahkan login kembali.';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('YOUR_API_BASE_URL/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat profil: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Siswa'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Fungsi untuk edit profil
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Edit Profil')));
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bagian foto profil
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileData['foto_path'] != null
                      ? NetworkImage(
                          'YOUR_API_BASE_URL/${profileData['foto_path']}')
                      : AssetImage('assets/profile_default.jpg')
                          as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 20),

          // Nama siswa
          Text(
            profileData['nama'] ?? 'Nama tidak tersedia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),

          // NIS/NISN
          Text(
            'NISN: ${profileData['nisn'] ?? 'Tidak tersedia'}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),

          // Kelas
          Text(
            'Kelas: ${profileData['kelas'] != null ? profileData['kelas']['nama'] : 'Tidak tersedia'} ${profileData['jurusan'] != null ? profileData['jurusan']['nama'] : ''}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 20),

          // Detail information cards
          _buildInfoCard('Informasi Pribadi', [
            {
              'label': 'Tanggal Lahir',
              'value': profileData['tanggal_lahir'] ?? 'Tidak tersedia'
            },
            {
              'label': 'Jenis Kelamin',
              'value': profileData['jenis_kelamin'] ?? 'Tidak tersedia'
            },
            {
              'label': 'Agama',
              'value': profileData['agama'] ?? 'Tidak tersedia'
            },
            {
              'label': 'Alamat',
              'value': profileData['alamat'] ?? 'Tidak tersedia'
            },
          ]),

          // You can add more cards here as needed
          SizedBox(height: 16),
          _buildInfoCard('Informasi Kontak', [
            {
              'label': 'Email',
              'value': profileData['email'] ?? 'Tidak tersedia'
            },
            {
              'label': 'No. Telepon',
              'value': profileData['telepon'] ?? 'Tidak tersedia'
            },
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, String>> items) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            Divider(),
            ...items
                .map((item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['label']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              item['value']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
