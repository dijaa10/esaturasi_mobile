import 'dart:convert';

class Tugas {
  final int id;
  final String judul;
  final String deskripsi;
  final String guru;
  final String deadline;
  final String status;
  final int attachments;
  final int? score;
  final String? imageUrl;
  final String? fotoPath;
  final String? mataPelajaran;

  Tugas({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.guru,
    required this.deadline,
    required this.status,
    required this.attachments,
    this.score,
    this.imageUrl,
    this.fotoPath,
    this.mataPelajaran,
  });

  factory Tugas.fromJson(Map<String, dynamic> json) {
    // Debugging print dulu biar kita tahu isi JSON di Flutter
    print('JSON diterima: ${jsonEncode(json)}');

    String guruValue = '';
    try {
      final slug = json['slug'];
      final jadwal = slug != null ? slug['jadwal'] : null;
      final guru = jadwal != null ? jadwal['guru'] : null;
      guruValue = guru != null && guru['nama'] != null
          ? guru['nama'].toString()
          : 'Tidak ada nama';
    } catch (e) {
      print('Error parsing guru name: $e');
      guruValue = 'Tidak ada nama';
    }

    String mataPelajaranValue = '';
    try {
      final slug = json['slug'];
      final jadwal = slug != null ? slug['jadwal'] : null;
      final mapel = jadwal != null ? jadwal['mata_pelajaran'] : null;
      mataPelajaranValue = mapel != null && mapel['nama_mapel'] != null
          ? mapel['nama_mapel'].toString()
          : 'Tidak ada nama mapel';
    } catch (e) {
      print('Error parsing mapel name: $e');
      mataPelajaranValue = 'Tidak ada nama mapel';
    }

    // Mengambil fotoPath dan mengubahnya menjadi URL
    String baseUrl = "http://10.0.2.2:8000/";
    String? imageUrl;
    if (json['file_path'] != null) {
      List<dynamic> filePaths = jsonDecode(json['file_path']);
      if (filePaths.isNotEmpty &&
          filePaths[0] is Map &&
          filePaths[0].containsKey('encrypted_name')) {
        String fotoPath = filePaths[0]['encrypted_name'];
        imageUrl =
            '$baseUrl/storage/file_tugas/$fotoPath'; // Menambahkan base URL
      }
    }

    return Tugas(
      id: json['id'],
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      guru: guruValue,
      deadline: json['deadline'] ?? '',
      status: json['status'] ?? 'Belum dikumpulkan',
      attachments: json['file_path'] != null
          ? (jsonDecode(json['file_path']).length)
          : 0,
      score: json['score'],
      imageUrl: imageUrl,
      fotoPath: json['file_path'],
      mataPelajaran: mataPelajaranValue,
    );
  }
}
