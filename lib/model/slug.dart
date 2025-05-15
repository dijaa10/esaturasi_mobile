class Slug {
  final int id;
  final String title;
  final String? deskripsi;
  final int jadwalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Slug({
    required this.id,
    required this.title,
    this.deskripsi,
    required this.jadwalId,
    this.createdAt,
    this.updatedAt,
  });

  factory Slug.fromJson(Map<String, dynamic> json) {
    return Slug(
      id: json['id'],
      title: json['title'],
      deskripsi: json['deskripsi'],
      jadwalId: json['jadwal_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'deskripsi': deskripsi,
      'jadwal_id': jadwalId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
