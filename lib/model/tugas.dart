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
  final String? imageUrl; // Menambahkan imageUrl ke model
  final String? fotoPath; // Mengubah fotoPath menjadi nullable

  Tugas({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.guru,
    required this.deadline,
    required this.status,
    required this.attachments,
    this.score,
    this.imageUrl, // Inisialisasi imageUrl
    this.fotoPath, // Menambahkan inisialisasi fotoPath
  });

  factory Tugas.fromJson(Map<String, dynamic> json) {
    // Ambil nama guru

    String guruValue = '';
    if (json.containsKey('guru') && json['guru'] is Map) {
      guruValue = json['guru']['nama']?.toString() ?? '';
    } else if (json.containsKey('nama_guru')) {
      guruValue = json['nama_guru']?.toString() ?? '';
    } else {
      guruValue = 'Tidak ada nama';
    }
    // Inisialisasi list kosong untuk filePath
    List<dynamic> filePathList = [];

    // Penanganan error saat mengurai file_path
    try {
      if (json['file_path'] != null &&
          json['file_path'].toString().isNotEmpty) {
        filePathList = jsonDecode(json['file_path']);
      }
    } catch (e) {
      print('Error parsing file_path: $e');
    }

    // Untuk Flutter Web di Chrome, gunakan localhost
    String baseUrl = 'http://127.0.0.1:8000';

    // Menginisialisasi imageUrl dan fotoPath
    String? imageUrl;
    String? fotoPath;

    if (filePathList.isNotEmpty &&
        filePathList[0] is Map &&
        filePathList[0].containsKey('encrypted_name')) {
      fotoPath = filePathList[0]['encrypted_name'];
      imageUrl = '$baseUrl/storage/$fotoPath';
    }

    return Tugas(
      id: json['id'],
      judul: json['judul'],
      deskripsi: json['deskripsi'],
      guru: guruValue,
      deadline: json['deadline'],
      status: json['status'] ?? 'Belum Dikerjakan',
      attachments: json['attachments'] ?? 0,
      score: json['score'],
      imageUrl: imageUrl, // Menggunakan URL lengkap
      fotoPath: fotoPath, // Menggunakan fotoPath yang valid atau null
    );
  }
}
