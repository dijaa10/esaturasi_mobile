import 'dart:convert';

class Materi {
  final int id;
  final String namaFile;
  final String filePath;
  final String? deskripsi;
  final int slugId;
  final String createdAt;
  final String updatedAt;

  Materi({
    required this.id,
    required this.namaFile,
    required this.filePath,
    this.deskripsi,
    required this.slugId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Materi.fromJson(Map<String, dynamic> json) {
    // Decode file_path dari string JSON menjadi list
    List<dynamic> filePathList = jsonDecode(json['file_path']);

    // Ambil nama file (bisa pilih original_name atau encrypted_name)
    String fileName = filePathList[0]['original_name'];
    String fileUrl = filePathList[0]['encrypted_name'];

    return Materi(
      id: json['id'],
      namaFile: fileName,
      filePath: fileUrl,
      deskripsi: json['deskripsi'],
      slugId: json['slug_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_file': namaFile,
      'file_path': jsonEncode([
        {
          'original_name': namaFile,
          'encrypted_name': filePath,
        }
      ]),
      'deskripsi': deskripsi,
      'slug_id': slugId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
