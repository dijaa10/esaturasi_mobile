class Pengumuman {
  final int id;
  final String title;
  final String content;
  final String date;

  Pengumuman({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    if (json.containsKey('date') &&
        json['date'] != null &&
        json['date'].toString().isNotEmpty) {
      tanggal = json['date'];
    } else if (json.containsKey('created_at') && json['created_at'] != null) {
      try {
        DateTime dateTime = DateTime.parse(json['created_at']);
        tanggal = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
      } catch (e) {
        print("Error parsing created_at: $e");
      }
    }

    return Pengumuman(
      id: json['id'] ?? 0,
      title: json['judul_pengumuman'] ?? 'Tanpa Judul',
      content: json['content_pengumuman'] ?? '-',
      date: tanggal,
    );
  }
}
