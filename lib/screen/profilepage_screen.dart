import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
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
      body: SingleChildScrollView(
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
                    backgroundImage: AssetImage('assets/profile_default.jpg'),
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
              'Budi Santoso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // NIS/NISN
            Text(
              'NISN: 0012345678',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),

            // Kelas
            Text(
              'Kelas: XI IPA 2',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 20),

            // Detail information cards
            _buildInfoCard('Informasi Pribadi', [
              {'label': 'Tanggal Lahir', 'value': '15 Agustus 2007'},
              {'label': 'Jenis Kelamin', 'value': 'Laki-laki'},
              {'label': 'Agama', 'value': 'Islam'},
              {'label': 'Alamat', 'value': 'Jl. Pendidikan No. 123, Jakarta'},
            ]),

            SizedBox(height: 16),

            _buildInfoCard('Informasi Akademik', [
              {'label': 'Tahun Masuk', 'value': '2022'},
              {'label': 'Wali Kelas', 'value': 'Ibu Siti Rahayu, S.Pd'},
              {'label': 'Absensi', 'value': '98%'},
              {'label': 'Rata-rata Nilai', 'value': '85.5'},
            ]),

            SizedBox(height: 16),

            _buildInfoCard('Informasi Kontak', [
              {'label': 'Email', 'value': 'budi.santoso@student.school.id'},
              {'label': 'No. Telepon', 'value': '081234567890'},
              {'label': 'Nama Orang Tua', 'value': 'Ahmad Santoso'},
              {'label': 'Kontak Orang Tua', 'value': '087654321098'},
            ]),

            SizedBox(height: 20),

            // Prestasi
            _buildAchievementSection(),

            SizedBox(height: 20),
          ],
        ),
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
                          Text(
                            item['value']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
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

  Widget _buildAchievementSection() {
    final achievements = [
      {
        'title': 'Juara 2 Olimpiade Matematika Tingkat Kota',
        'date': 'November 2023'
      },
      {'title': 'Peserta Lomba Debat Bahasa Inggris', 'date': 'April 2024'},
      {'title': 'Anggota OSIS - Seksi Bidang Akademik', 'date': '2023 - 2024'},
    ];

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
              'Prestasi & Aktivitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            Divider(),
            ...achievements
                .map((achievement) => ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      leading: Icon(Icons.emoji_events, color: Colors.amber),
                      title: Text(achievement['title']!),
                      subtitle: Text(achievement['date']!),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
