class Student {
  final int id;
  final String nisn;
  final String name;
  final String dateOfBirth;
  final String placeOfBirth;
  final int classroomId;
  final String gender;
  final String address;
  final String avatarUrl;
  final String email;
  final String? emailVerifiedAt;
  final String createdAt;
  final String updatedAt;
  final Classroom classroom;

  Student({
    required this.id,
    required this.nisn,
    required this.name,
    required this.dateOfBirth,
    required this.placeOfBirth,
    required this.classroomId,
    required this.gender,
    required this.address,
    required this.avatarUrl,
    required this.email,
    this.emailVerifiedAt, // Nullable
    required this.createdAt,
    required this.updatedAt,
    required this.classroom,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      nisn: json['nisn'] ?? "",
      name: json['name'] ?? "",
      dateOfBirth: json['date_of_birth'] ?? "",
      placeOfBirth: json['place_of_birth'] ?? "",
      classroomId: json['classroom_id'] ?? 0,
      gender: json['gender'] ?? "",
      address: json['address'] ?? "",
      avatarUrl: json['avatar_url'] ?? "",
      email: json['email'] ?? "",
      emailVerifiedAt: json['email_verified_at']?.toString(), // Nullable
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
      classroom: Classroom.fromJson(json['classroom'] ?? {}),
    );
  }
}

class Classroom {
  final int id;
  final String name;
  final int majorId;
  final String createdAt;
  final String updatedAt;
  final Major major;

  Classroom({
    required this.id,
    required this.name,
    required this.majorId,
    required this.createdAt,
    required this.updatedAt,
    required this.major,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      majorId: json['major_id'] ?? 0,
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
      major: Major.fromJson(json['major'] ?? {}),
    );
  }
}

class Major {
  final int id;
  final String code;
  final String name;
  final String createdAt;
  final String updatedAt;

  Major({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(
      id: json['id'] ?? 0,
      code: json['code'] ?? "",
      name: json['name'] ?? "",
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
    );
  }
}
