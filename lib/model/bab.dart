class Bab {
  final int id;
  final String judul;
  final int jadwalId;

  Bab({
    required this.id,
    required this.judul,
    required this.jadwalId,
  });

  factory Bab.fromJson(Map<String, dynamic> json) {
    return Bab(
      id: json['id'],
      judul: json['judul'],
      jadwalId: json['jadwal_id'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'jadwal_id': jadwalId,
    };
  }
}
