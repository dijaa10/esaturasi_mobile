import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Jadwal {
  final String mataPelajaran;
  final String jamMulai;
  final String jamSelesai;
  final String guru;

  Jadwal({
    required this.mataPelajaran,
    required this.jamMulai,
    required this.jamSelesai,
    required this.guru,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      mataPelajaran: json['jadwal_mata_pelajaran']['nama'] ?? 'N/A',
      jamMulai: json['jam_mulai'] ?? 'N/A',
      jamSelesai: json['jam_selesai'] ?? 'N/A',
      guru: json['guru']['name'] ?? 'N/A',
    );
  }
}

Future<List<Jadwal>> fetchJadwal() async {
  final response = await http.get(
    Uri.parse('http:/127.0.0.1:8000/jadwal'), // Ganti dengan URL API Anda
    headers: {'Authorization': 'Bearer YOUR_ACCESS_TOKEN'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Jadwal.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load jadwal');
  }
}
