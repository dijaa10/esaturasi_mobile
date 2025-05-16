// lib/model/announcement.dart

class Announcement {
  final int id;
  final String title;
  final String content;
  final String date;
  final String? author;
  final String? attachmentUrl;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.author,
    this.attachmentUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'] ?? '',
      date: json['created_at'] ?? DateTime.now().toString(),
      author: json['author'] ?? json['posted_by'],
      attachmentUrl: json['attachment_url'] ?? json['lampiran'],
    );
  }
}
