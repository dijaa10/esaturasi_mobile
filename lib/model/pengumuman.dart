class Pengumuman {
  final int id;
  final String judul;
  final String content;
  final String? arsipPath;

  Pengumuman({
    required this.id,
    required this.judul,
    required this.content,
    this.arsipPath,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    return Pengumuman(
      id: json['id'],
      judul: json['judul_pengumuman'],
      content: json['content_pengumuman'],
      arsipPath: json['arsip'] != null ? json['arsip']['file_path'] : null,
    );
  }
}
