import 'package:flutter/foundation.dart';

class Jadwal {
  final int id;
  final String mataPelajaran;
  final String hari;
  final String kelas;
  final String jamMulai;
  final String jamSelesai;
  final String guru;

  Jadwal({
    required this.id,
    required this.mataPelajaran,
    required this.hari,
    required this.kelas,
    required this.jamMulai,
    required this.jamSelesai,
    required this.guru,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    // Debug print untuk melihat data yang masuk dari API
    if (kDebugMode) {
      print("Raw JSON data: $json");
    }

    // Ambil nama mata pelajaran dari relasi atau ID
    String mataPelajaranValue = '';
    if (json.containsKey('mata_pelajaran') && json['mata_pelajaran'] is Map) {
      mataPelajaranValue = json['mata_pelajaran']['nama']?.toString() ?? '';
    } else if (json.containsKey('nama_mapel')) {
      mataPelajaranValue = json['nama_mapel']?.toString() ?? '';
    } else if (json.containsKey('mata_pelajaran_id')) {
      mataPelajaranValue = 'ID Mapel: ${json['mata_pelajaran_id']}';
    } else {
      mataPelajaranValue = 'Tidak ada nama';
    }

    // Ambil nama kelas dari relasi atau ID
    String kelasValue = '';
    if (json.containsKey('kelas') && json['kelas'] is Map) {
      kelasValue = json['kelas']['nama']?.toString() ?? '';
    } else if (json.containsKey('nama_kelas')) {
      kelasValue = json['nama_kelas']?.toString() ?? '';
    } else if (json.containsKey('kelas_id')) {
      kelasValue = 'Kelas: ${json['kelas_id']}';
    } else {
      kelasValue = 'Tidak ada nama';
    }

    // Ambil nama guru
    String guruValue = '';
    if (json.containsKey('guru') && json['guru'] is Map) {
      guruValue = json['guru']['nama']?.toString() ?? '';
    } else if (json.containsKey('nama_guru')) {
      guruValue = json['nama_guru']?.toString() ?? '';
    } else {
      guruValue = 'Tidak ada nama';
    }

    // Menangani berbagai kemungkinan nama field untuk hari
    String dayValue = json['hari']?.toString() ??
        json['day']?.toString() ??
        json['nama_hari']?.toString() ??
        'Tidak diketahui'; // Default jika tidak ditemukan

    // Normalisasi nama hari jika diperlukan
    dayValue = _normalizeDayName(dayValue);

    // Debug print hasil parsing
    if (kDebugMode) {
      print("Nama Mata Pelajaran: $mataPelajaranValue");
      print("Nama Kelas: $kelasValue");
      print("Nama Guru: $guruValue");
    }

    return Jadwal(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      mataPelajaran: mataPelajaranValue,
      hari: dayValue,
      kelas: kelasValue,
      jamMulai: json['jam_mulai']?.toString() ?? '00:00',
      jamSelesai: json['jam_selesai']?.toString() ?? '00:00',
      guru: guruValue,
    );
  }

  static String _normalizeDayName(String day) {
    day = day.trim().toLowerCase();
    final Map<String, String> dayMap = {
      'sen': 'Senin',
      'senin': 'Senin',
      'monday': 'Senin',
      'sel': 'Selasa',
      'selasa': 'Selasa',
      'tuesday': 'Selasa',
      'rab': 'Rabu',
      'rabu': 'Rabu',
      'wednesday': 'Rabu',
      'kam': 'Kamis',
      'kamis': 'Kamis',
      'thursday': 'Kamis',
      'jum': 'Jumat',
      'jumat': 'Jumat',
      'jum\'at': 'Jumat',
      'friday': 'Jumat',
    };
    return dayMap[day] ?? day.substring(0, 1).toUpperCase() + day.substring(1);
  }

  // Override toString untuk debugging
  @override
  String toString() {
    return 'guru: $guru, jamSelesai: $jamSelesai, jamMulai: $jamMulai, kelas: $kelas, hari: $hari, mataPelajaran: $mataPelajaran';
  }

  // Alternatif tampilan string terurut
  String toOrderedString() {
    return '$guru $jamSelesai $jamMulai $kelas $hari $mataPelajaran';
  }

  // Format ke dalam Map yang terurut
  Map<String, String> toOrderedMap() {
    return {
      'guru': guru,
      'jamSelesai': jamSelesai,
      'jamMulai': jamMulai,
      'kelas': kelas,
      'hari': hari,
      'mataPelajaran': mataPelajaran,
    };
  }
}
