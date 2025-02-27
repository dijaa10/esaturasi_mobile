class Siswa {
  final int id;
  final String nisn;
  final String nama;
  final String tanggalLahir;
  final String tempatLahir;
  final int kelasId;
  final int jurusanId;
  final String jenisKelamin;
  final String alamat;
  final String fotoProfil;
  final String tahunMasuk;
  final String status;
  final String email;
  final String? emailVerifiedAt; // Nullable
  final String createdAt;
  final String updatedAt;
  final Kelas kelas;
  final Jurusan jurusan;

  Siswa({
    required this.id,
    required this.nisn,
    required this.nama,
    required this.tanggalLahir,
    required this.tempatLahir,
    required this.kelasId,
    required this.jurusanId,
    required this.jenisKelamin,
    required this.alamat,
    required this.fotoProfil,
    required this.tahunMasuk,
    required this.status,
    required this.email,
    this.emailVerifiedAt, // Nullable
    required this.createdAt,
    required this.updatedAt,
    required this.kelas,
    required this.jurusan,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      id: json['id'],
      nisn: json['nisn'] ?? "",
      nama: json['nama'] ?? "",
      tanggalLahir: json['tanggal_lahir'] ?? "",
      tempatLahir: json['tempat_lahir'] ?? "",
      kelasId: json['kelas_id'] ?? 0,
      jurusanId: json['jurusan_id'] ?? 0,
      jenisKelamin: json['jenis_kelamin'] ?? "",
      alamat: json['alamat'] ?? "",
      fotoProfil: json['foto_profil'] ?? "",
      tahunMasuk: json['tahun_masuk'] ?? "",
      status: json['status'] ?? "",
      email: json['email'] ?? "",
      emailVerifiedAt: json['email_verified_at']?.toString(), // Nullable
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
      kelas: Kelas.fromJson(json['kelas'] ?? {}),
      jurusan: Jurusan.fromJson(json['jurusan'] ?? {}),
    );
  }
}

class Kelas {
  final int id;
  final String namaKelas;
  final int jurusanId;
  final String createdAt;
  final String updatedAt;

  Kelas({
    required this.id,
    required this.namaKelas,
    required this.jurusanId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      id: json['id'] ?? 0,
      namaKelas: json['nama_kelas'] ?? "",
      jurusanId: json['jurusan_id'] ?? 0,
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
    );
  }
}

class Jurusan {
  final int id;
  final String kodeJurusan;
  final String namaJurusan;
  final String createdAt;
  final String updatedAt;

  Jurusan({
    required this.id,
    required this.kodeJurusan,
    required this.namaJurusan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Jurusan.fromJson(Map<String, dynamic> json) {
    return Jurusan(
      id: json['id'] ?? 0,
      kodeJurusan: json['kode_jurusan'] ?? "",
      namaJurusan: json['nama_jurusan'] ?? "",
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
    );
  }
}
