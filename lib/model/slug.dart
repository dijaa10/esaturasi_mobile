class Slug {
  final int id;
  final String title; // Changed from judul
  final String slug; // Added new field
  final int scheduleId; // Changed from jadwalId
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Slug({
    required this.id,
    required this.title, // Changed from judul
    required this.slug, // Added new required field
    required this.scheduleId, // Changed from jadwalId
    this.createdAt,
    this.updatedAt,
  });

  factory Slug.fromJson(Map<String, dynamic> json) {
    return Slug(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      scheduleId: int.tryParse(json['schedule_id'].toString()) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title, // Changed from judul
      'slug': slug, // Added new field
      'schedule_id': scheduleId, // Changed from jadwal_id
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
