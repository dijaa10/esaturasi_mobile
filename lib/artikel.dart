import 'package:flutter/material.dart';

class ArtikelScreen extends StatelessWidget {
  const ArtikelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> articles = [
      {
        'image': 'assets/images/artikel/wisuda.png',
        'title':
            'Meriah dan Penuh Haru, Wisuda Siswa SMK Negeri 1 Sumberasih Tahun Ini Menjadi Momen Tak Terlupakan',
        'time': '30 menit yang lalu',
      },
      {
        'image': 'assets/images/artikel/sepakbola.png',
        'title':
            'Tim Sepak Bola SMK Negeri 1 Sumberasih Raih Gelar Juara dalam Turnamen Antar Sekolah',
        'time': '1 hari yang lalu',
      },
      {
        'image': 'assets/images/artikel/kunjungan.png',
        'title':
            'Semangat Tinggi! Siswa SMK Persiapkan Diri untuk Magang di Luar Negeri',
        'time': '3 hari yang lalu',
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Artikel', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return _buildArticleCard(articles[index]);
        },
      ),
    );
  }

  Widget _buildArticleCard(Map<String, String> article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              article['image']!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${article['time']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
