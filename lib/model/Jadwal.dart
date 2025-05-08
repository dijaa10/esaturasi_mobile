import 'dart:convert';
import 'package:flutter/foundation.dart';

class Jadwal {
  final int id;
  final String mataPelajaran;
  final String hari;
  final String kelas;
  final String jamMulai;
  final String jamSelesai;
  final String guru;
  final int idMapel;

  Jadwal({
    required this.id,
    required this.mataPelajaran,
    required this.hari,
    required this.kelas,
    required this.jamMulai,
    required this.jamSelesai,
    required this.guru,
    required this.idMapel,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("Raw JSON data: $json");
    }

    // Ambil nama mapel
    String mataPelajaranValue = '';
    if (json.containsKey('mata_pelajaran') && json['mata_pelajaran'] is Map) {
      mataPelajaranValue =
          json['mata_pelajaran']['nama_mapel']?.toString() ?? '';
    } else if (json.containsKey('nama_mapel')) {
      mataPelajaranValue = json['nama_mapel']?.toString() ?? '';
    } else {
      mataPelajaranValue = 'Tidak ada mapel';
    }

    // Ambil nama kelas
    String kelasValue = '';
    if (json.containsKey('kelas') && json['kelas'] is Map) {
      kelasValue = json['kelas']['nama_kelas']?.toString() ?? '';
    } else if (json.containsKey('nama_kelas')) {
      kelasValue = json['nama_kelas']?.toString() ?? '';
    } else {
      kelasValue = 'Tidak ada kelas';
    }

    // Ambil nama guru
    String guruValue = '';
    if (json.containsKey('guru') && json['guru'] is Map) {
      guruValue = json['guru']['nama']?.toString() ?? '';
    } else if (json.containsKey('nama_guru')) {
      guruValue = json['nama_guru']?.toString() ?? '';
    } else {
      guruValue = 'Tidak ada guru';
    }

    // Ambil hari
    String hariValue = '';
    try {
      // Pastikan "hari" adalah string yang valid, lalu decode JSON
      if (json['hari'] is String) {
        List<dynamic> hariList = jsonDecode(json['hari']);
        // Pastikan hariList tidak kosong
        if (hariList.isNotEmpty && hariList[0] is String) {
          hariValue = hariList[0].toString();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing hari: $e");
      }
      hariValue = 'Format tidak valid';
    }

    // Ambil jam mulai dan jam selesai
    String jamMulaiValue = '';
    String jamSelesaiValue = '';
    try {
      // Decode string JSON untuk jam mulai dan jam selesai
      if (json['jam_mulai'] is String && json['jam_selesai'] is String) {
        Map<String, dynamic> jamMulaiMap = jsonDecode(json['jam_mulai']);
        Map<String, dynamic> jamSelesaiMap = jsonDecode(json['jam_selesai']);

        // Ambil data jam berdasarkan hari yang sudah didapatkan
        if (hariValue.isNotEmpty) {
          jamMulaiValue = jamMulaiMap[hariValue] ?? '';
          jamSelesaiValue = jamSelesaiMap[hariValue] ?? '';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing waktu: $e");
      }
    }

    return Jadwal(
      id: json['id'],
      mataPelajaran: mataPelajaranValue,
      hari: hariValue, // Hanya nama hari saja
      kelas: kelasValue,
      jamMulai: jamMulaiValue,
      jamSelesai: jamSelesaiValue,
      guru: guruValue,
      idMapel: json['mata_pelajaran_id'],
    );
  }
}
