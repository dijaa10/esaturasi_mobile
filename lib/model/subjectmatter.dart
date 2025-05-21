import 'package:flutter/material.dart';

class Subjectmatter {
  final int id;
  final int slugId;
  final String title;
  final String? description;
  final String filePath;
  final String createdAt;
  final String updatedAt;

  Subjectmatter({
    required this.id,
    required this.slugId,
    required this.title,
    this.description,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subjectmatter.fromJson(Map<String, dynamic> json) {
    return Subjectmatter(
      id: int.tryParse(json['id'].toString()) ?? 0,
      slugId: int.tryParse(json['slug_id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      filePath: json['file_path']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
