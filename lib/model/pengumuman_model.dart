class Pengumuman {
  final int id;
  final String title;
  final String content;
  final String date;
  final String? author;
  final String? attachmentUrl;

  Pengumuman({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.author,
    this.attachmentUrl,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    return Pengumuman(
      id: json['id'],
      title: json['title'],
      content: json['content'] ?? '',
      date: json['date'] ?? json['created_at'] ?? DateTime.now().toString(),
      author: json['author'] ?? json['posted_by'],
      attachmentUrl: json['attachment_url'] ?? json['lampiran'],
    );
  }
}
