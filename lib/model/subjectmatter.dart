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
      id: json['id'] as int,
      slugId: json['slug_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      filePath: json['file_path'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
