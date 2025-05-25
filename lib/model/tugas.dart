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
  final String? siswaId;
  final String? submittedAt; // Tambahkan property ini
  final String? updatedAt;

  Tugas(
      {required this.id,
      required this.judul,
      required this.deskripsi,
      required this.guru,
      required this.deadline,
      required this.status,
      required this.attachments,
      this.score,
      this.fotoPath,
      this.mataPelajaran,
      this.siswaId,
      this.submittedAt,
      this.updatedAt});

  static const String baseUrl = "https://esaturasi.my.id";

  String? get imageUrl {
    if (fotoPath != null && fotoPath!.isNotEmpty) {
      return '$baseUrl/storage/$fotoPath';
    }
    return null;
  }

  factory Tugas.fromJson(Map<String, dynamic> json) {
    return Tugas(
      id: int.tryParse(json['id'].toString()) ?? 0,
      judul: json['judul']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? '',
      guru: json['guru']?.toString() ?? 'Guru tidak diketahui',
      deadline: json['deadline']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Belum dikumpulkan',
      attachments: int.tryParse(json['attachments'].toString()) ?? 0,
      score:
          json['score'] != null ? int.tryParse(json['score'].toString()) : null,
      fotoPath: json['file_path']?.toString(),
      mataPelajaran: json['mata_pelajaran']?.toString() ??
          'Mata pelajaran tidak diketahui',
      siswaId: json['siswa_id']?.toString(),
      submittedAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get statusText {
    switch (status) {
      case 'submitted':
        return 'Sudah Dikumpulkan';
      case 'graded':
        return 'Sudah Dinilai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'submitted':
        return '#FFC107';
      case 'graded':
        return '#4CAF50';
      case 'rejected':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
}
