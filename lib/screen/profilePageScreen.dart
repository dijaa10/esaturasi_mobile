import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../loginpage_screen.dart';

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
  final String baseUrl = "http://10.0.2.2:8000/";
  final ImagePicker _picker = ImagePicker();

  // Premium UI colors
  final Color primaryColor = Color(0xFF1976D2); // Deep Blue
  final Color accentColor = Color(0xFF64B5F6); // Light Blue
  final Color bgColor = Color(0xFFF8F9FA); // Light Gray background
  final Color cardColor = Colors.white;
  final Color textColor = Color(0xFF2D3142); // Dark text

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data functions
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

    // Fetch class and major based on ID
    String? idKelas = prefs.getString('kelas_id');
    String? idJurusan = prefs.getString('kelas_id');

    if (idKelas != null) _fetchKelas(idKelas);
    if (idJurusan != null) _fetchJurusan(idJurusan);
  }

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

  Future<void> _fetchJurusan(String idKelas) async {
    try {
      final response = await http.get(
        Uri.parse("${baseUrl}api/get-jurusan-by-kelas/$idKelas"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaJurusan = data['nama_jurusan'] ?? "Jurusan Tidak Ditemukan";
        });
      } else {
        setState(() {
          namaJurusan = "Jurusan Tidak Ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        namaJurusan = "Gagal Memuat Jurusan";
      });
    }
  }

  // Logout confirmation dialog
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFEE2E2), // Light red background
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626), // Red icon
                    size: 32,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Konfirmasi Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Apakah Anda yakin ingin keluar dari aplikasi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Ya, Keluar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _logout(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Logout function
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Image selection functions
  Future<void> _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _uploadImage(File(image.path));
    }
  }

  Future<void> _getImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _uploadImage(File(photo.path));
    }
  }

  Future<void> _deleteProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showCustomSnackBar('Token tidak ditemukan. Silakan login ulang.',
            isSuccess: false);
        return;
      }

      final response = await http.delete(
        Uri.parse("${baseUrl}api/delete-profile-photo"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Optional: Cek isi response JSON
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['message'] != null) {
          if (mounted) {
            setState(() {
              fotoProfil = "https://via.placeholder.com/150";
            });
          }
          await prefs.setString('foto_profil', "");
          _showCustomSnackBar(responseBody['message'], isSuccess: true);
        } else {
          _showCustomSnackBar('Foto profil berhasil dihapus.', isSuccess: true);
        }
      } else {
        final Map<String, dynamic> errorBody = json.decode(response.body);
        final message = errorBody['message'] ?? 'Gagal menghapus foto profil.';
        _showCustomSnackBar(message, isSuccess: false);
      }
    } catch (e) {
      _showCustomSnackBar('Terjadi kesalahan: $e', isSuccess: false);
    }
  }

  // Upload image function
  Future<void> _uploadImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('api_token');

      var request = http.MultipartRequest(
          'POST', Uri.parse("${baseUrl}api/update-profile-photo"));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(
          await http.MultipartFile.fromPath('foto_profil', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fotoProfil = data['foto_url'] ?? fotoProfil;
        });

        await prefs.setString('foto_profil', data['foto_path'] ?? "");

        _showCustomSnackBar('Foto profil berhasil diperbarui', isSuccess: true);
      } else {
        _showCustomSnackBar('Gagal memperbarui foto profil', isSuccess: false);
      }
    } catch (e) {
      _showCustomSnackBar('Terjadi kesalahan: $e', isSuccess: false);
    }
  }

  // Custom snackbar function
  void _showCustomSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        backgroundColor:
            isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  // Profile photo options sheet
  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 24),
              _buildOptionItem(
                icon: Icons.photo_library_rounded,
                text: 'Pilih dari Galeri',
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromGallery();
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildOptionItem(
                icon: Icons.camera_alt_rounded,
                text: 'Ambil Foto',
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromCamera();
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildOptionItem(
                icon: Icons.delete_rounded,
                text: 'Hapus Foto',
                isDelete: true,
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePhoto();
                },
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: textColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  // Option item widget
  Widget _buildOptionItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDelete
                    ? Color(0xFFFEE2E2) // Light red background
                    : Color(0xFFE0F2FE), // Light blue background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDelete ? Color(0xFFDC2626) : accentColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDelete ? Color(0xFFDC2626) : textColor,
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
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Profil Saya",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor,
                    accentColor,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, 10),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _showProfilePhotoOptions,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(fotoProfil),
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                  print("Error loading image: $exception");
                                },
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        nama,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Information section
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Informasi Akademik",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoCard(
                    title: "Kelas",
                    value: namaKelas,
                    icon: Icons.school_rounded,
                    iconColor: Color(0xFF0369A1), // Blue
                    bgColor: Color(0xFFE0F2FE), // Light blue
                  ),
                  SizedBox(height: 16),
                  _buildInfoCard(
                    title: "Jurusan",
                    value: namaJurusan,
                    icon: Icons.book_rounded,
                    iconColor: Color(0xFF4F46E5), // Indigo
                    bgColor: Color(0xFFE0E7FF), // Light indigo
                  ),
                  SizedBox(height: 16),
                  _buildInfoCard(
                    title: "Email",
                    value: email,
                    icon: Icons.email_rounded,
                    iconColor: Color(0xFF059669), // Green
                    bgColor: Color(0xFFD1FAE5), // Light green
                  ),
                  SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showLogoutConfirmationDialog(context);
                      },
                      icon: Icon(Icons.logout_rounded),
                      label: Text(
                        "Keluar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFEE2E2), // Light red
                        foregroundColor: Color(0xFFDC2626), // Red
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

  // Enhanced info card widget
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
