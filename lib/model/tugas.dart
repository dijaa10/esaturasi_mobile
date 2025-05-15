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
  final String? fotoPath;
  final String? mataPelajaran;
  final String siswaId;

  Tugas({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.guru,
    required this.deadline,
    required this.status,
    required this.attachments,
    this.score,
    this.fotoPath,
    this.mataPelajaran,
    required this.siswaId,
  });

  static const String baseUrl = "http://10.0.2.2:8000";

  String? get imageUrl {
    if (fotoPath != null && fotoPath!.isNotEmpty) {
      return '$baseUrl/storage/$fotoPath';
    }
    return null;
  }

  factory Tugas.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as Map<String, dynamic>?;
    final schedule = slug?['schedule'] as Map<String, dynamic>?;

    final teacher = schedule?['teacher'] as Map<String, dynamic>?;
    final guruValue = teacher?['name']?.toString() ?? 'Tidak ada nama';

    final subject = schedule?['subject'] as Map<String, dynamic>?;
    final mapelValue = subject?['name']?.toString() ?? 'Tidak ada nama mapel';

    String? fotoPathValue;
    int attachmentsCount = 0;

    if (json['file_path'] != null) {
      try {
        List<dynamic> filePaths = jsonDecode(json['file_path']);
        attachmentsCount = filePaths.length;
        if (filePaths.isNotEmpty &&
            filePaths[0] is Map &&
            filePaths[0].containsKey('encrypted_name')) {
          fotoPathValue = filePaths[0]['encrypted_name'];
        }
      } catch (e) {
        print('Error parsing file_path: $e');
      }
    }

    return Tugas(
      id: json['id'],
      judul: json['title'] ?? '',
      deskripsi: json['description'] ?? '',
      guru: guruValue,
      deadline: json['deadline'] ?? '',
      status: json['status'] ?? 'Belum dikumpulkan',
      attachments: attachmentsCount,
      score: json['score'],
      fotoPath: fotoPathValue,
      mataPelajaran: mapelValue,
      siswaId: json['siswa_id'].toString(),
    );
  }
}
