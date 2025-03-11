import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Jadwal {
  final String mataPelajaran;
  final String jamMulai;
  final String jamSelesai;
  final String hari;
  final String guru;
  final String kelas;

  Jadwal({
    required this.mataPelajaran,
    required this.jamMulai,
    required this.jamSelesai,
    required this.hari,
    required this.guru,
    required this.kelas,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      mataPelajaran: json['mata_pelajaran'] != null
          ? json['mata_pelajaran']['nama']
          : 'N/A',
      jamMulai: json['jam_mulai'] ?? 'N/A',
      jamSelesai: json['jam_selesai'] ?? 'N/A',
      hari: json['hari'] ?? 'N/A',
      guru: json['guru'] != null ? json['guru']['name'] : 'N/A',
      kelas: json['kelas'] != null ? json['kelas']['nama'] : 'N/A',
    );
  }
}
