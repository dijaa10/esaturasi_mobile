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
    this.siswaId,
  });

  static const String baseUrl = "http://10.0.2.2:8000";

  String? get imageUrl {
    if (fotoPath != null && fotoPath!.isNotEmpty) {
      return '$baseUrl/storage/$fotoPath';
    }
    return null;
  }

  factory Tugas.fromJson(Map<String, dynamic> json) {
    return Tugas(
      id: json['id'],
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      guru: json['guru'] ?? 'Guru tidak diketahui',
      deadline: json['deadline'] ?? '',
      status: json['status'] ?? 'Belum dikumpulkan',
      attachments: json['attachments'] ?? 0,
      score: json['score'],
      fotoPath: json['file_path'],
      mataPelajaran: json['mata_pelajaran'] ?? 'Mata pelajaran tidak diketahui',
      siswaId: json['siswa_id']?.toString(),
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
