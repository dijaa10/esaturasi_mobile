import 'package:flutter/material.dart';

class DetailArtikelScreen extends StatelessWidget {
  final String title;
  final String image;
  final String time;

  DetailArtikelScreen(
      {required this.title, required this.image, required this.time});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title:
            const Text('Detail Artikel', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(image,
                fit: BoxFit.cover, width: double.infinity, height: 200),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(time, style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 10),
                  Divider(),
                  Text(
                    'Pada hari yang ditunggu-tunggu, acara wisuda siswa SMK Negeri 1 Sumberasih berlangsung dengan penuh kemeriahan dan haru. Kegiatan yang dilaksanakan di [lokasi wisuda] ini dihadiri oleh para siswa, orang tua, guru, serta tamu undangan, menjadikan hari tersebut sebagai momen istimewa bagi semua yang hadir.Acara dimulai dengan sambutan hangat dari Kepala Sekolah, yang mengapresiasi kerja keras para siswa selama menempuh pendidikan. Dalam sambutannya, beliau menyampaikan rasa bangga atas pencapaian siswa, baik dalam bidang akademik maupun non-akademik. "Hari ini adalah puncak dari segala usaha dan perjuangan kalian. Tetaplah bersemangat, karena ini bukan akhir, melainkan awal dari perjalanan yang lebih menantang di masa depan," ungkapnya. Kenangan Manis Bersama Wisuda tidak hanya menjadi perayaan kelulusan, tetapi juga momen untuk mengenang kebersamaan selama di sekolah. Para siswa terlihat saling memberikan ucapan selamat dan berfoto bersama, mengenang perjalanan panjang yang mereka tempuh bersama-sama. Tawa, air mata, dan canda tawa mewarnai suasana, menciptakan kenangan manis yang akan mereka bawa ke mana pun mereka pergi. Salah satu siswa yang diwawancarai, Dwi Yulianti, mengungkapkan perasaannya. "Ini adalah momen yang sangat berarti bagi saya. Tidak hanya karena akhirnya kami lulus, tetapi juga karena kami telah melalui banyak hal bersama. Saya akan sangat merindukan teman-teman dan guru-guru di sini," katanya sambil tersenyum.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
