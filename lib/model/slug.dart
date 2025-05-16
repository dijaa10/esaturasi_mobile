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
      id: json['id'] ?? 0,
      title: json['title'] ?? '', // Changed from judul
      slug: json['slug'] ?? '', // Added new field
      scheduleId: json['schedule_id'] ?? 0, // Changed from jadwal_id
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
      'title': title, // Changed from judul
      'slug': slug, // Added new field
      'schedule_id': scheduleId, // Changed from jadwal_id
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
