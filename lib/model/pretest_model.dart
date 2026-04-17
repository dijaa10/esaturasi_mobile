class PretestModel {
  final int id;
  final int slugId;
  final String judul;
  final int kkm;
  final String waktuMulai;
  final String waktuSelesai;
  final List<SoalModel> soal;

  PretestModel({
    required this.id,
    required this.slugId,
    required this.judul,
    required this.kkm,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.soal,
  });

  // Gunakan IP 10.0.2.2 untuk Emulator Android
  static const String baseUrl = "http://10.0.2.2:8000";

  factory PretestModel.fromJson(Map<String, dynamic> json) {
    var listSoal = json['soal'] as List? ?? [];
    List<SoalModel> soalList =
        listSoal.map((i) => SoalModel.fromJson(i)).toList();

    return PretestModel(
      id: json['id'] ?? 0,
      slugId: json['slug_id'] ?? 0,
      judul: json['judul'] ?? '',
      kkm: json['kkm'] ?? 0,
      waktuMulai: json['waktu_mulai'] ?? '',
      waktuSelesai: json['waktu_selesai'] ?? '',
      soal: soalList,
    );
  }
}

class SoalModel {
  final int id;
  final String pertanyaan;
  final String opsiA;
  final String opsiB;
  final String opsiC;
  final String opsiD;
  final String jawabanBenar;

  SoalModel({
    required this.id,
    required this.pertanyaan,
    required this.opsiA,
    required this.opsiB,
    required this.opsiC,
    required this.opsiD,
    required this.jawabanBenar,
  });

  factory SoalModel.fromJson(Map<String, dynamic> json) {
    return SoalModel(
      id: json['id'] ?? 0,
      pertanyaan: json['soal'] ?? '',
      opsiA: json['opsi_a'] ?? '',
      opsiB: json['opsi_b'] ?? '',
      opsiC: json['opsi_c'] ?? '',
      opsiD: json['opsi_d'] ?? '',
      jawabanBenar: json['jawaban'] ?? '',
    );
  }
}
