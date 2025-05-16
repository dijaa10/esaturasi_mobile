import 'dart:convert';
import 'package:flutter/foundation.dart';

class Jadwal {
  final int id;
  final String mataPelajaran;
  final String kelas;
  final String guru;
  final int idMapel;

  // Data multi-hari dalam format Map
  final List<Map<String, dynamic>> scheduleData; // Menyimpan semua data jadwal

  // Properti untuk tampilan saat ini (untuk satu hari tertentu)
  String hari;
  String jamMulai;
  String jamSelesai;

  Jadwal({
    required this.id,
    required this.mataPelajaran,
    required this.kelas,
    required this.guru,
    required this.idMapel,
    required this.scheduleData,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("Raw JSON data: $json");
    }

    // Ambil nama mapel dari relasi subject
    String mataPelajaranValue = '';
    if (json.containsKey('subject') && json['subject'] is Map) {
      mataPelajaranValue = json['subject']['name']?.toString() ?? '';
    } else if (json.containsKey('subject_name')) {
      mataPelajaranValue = json['subject_name']?.toString() ?? '';
    } else {
      mataPelajaranValue = 'Tidak ada mapel';
    }

    // Ambil nama kelas dari relasi classroom
    String kelasValue = '';
    if (json.containsKey('classroom') && json['classroom'] is Map) {
      kelasValue = json['classroom']['name']?.toString() ?? '';
    } else if (json.containsKey('classroom_name')) {
      kelasValue = json['classroom_name']?.toString() ?? '';
    } else {
      kelasValue = 'Tidak ada kelas';
    }

    // Ambil nama guru dari relasi teacher
    String guruValue = '';
    if (json.containsKey('teacher') && json['teacher'] is Map) {
      guruValue = json['teacher']['name']?.toString() ?? '';
    } else if (json.containsKey('teacher_name')) {
      guruValue = json['teacher_name']?.toString() ?? '';
    } else {
      guruValue = 'Tidak ada guru';
    }

    // Parse data schedule
    List<Map<String, dynamic>> scheduleData = [];

    try {
      // Cek jika schedule ada dalam format yang tepat
      if (json.containsKey('schedule')) {
        var schedule = json['schedule'];

        // Jika sudah dalam bentuk List
        if (schedule is List) {
          scheduleData = List<Map<String, dynamic>>.from(schedule.map((item) =>
              item is Map
                  ? Map<String, dynamic>.from(item)
                  : {"day": "Invalid", "start": "", "end": ""}));
        }
        // Jika dalam bentuk String JSON
        else if (schedule is String) {
          try {
            var decodedSchedule = jsonDecode(schedule);
            if (decodedSchedule is List) {
              scheduleData = List<Map<String, dynamic>>.from(
                  decodedSchedule.map((item) => item is Map
                      ? Map<String, dynamic>.from(item)
                      : {"day": "Invalid", "start": "", "end": ""}));
            }
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing schedule string: $e");
            }
            scheduleData = [
              {"day": "Format tidak valid", "start": "", "end": ""}
            ];
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing schedule: $e");
      }
      scheduleData = [
        {"day": "Error", "start": "", "end": ""}
      ];
    }

    // Default untuk tampilan awal - gunakan hari pertama jika ada
    String hariDefault =
        scheduleData.isNotEmpty ? scheduleData[0]["day"] : 'Tidak ada';
    String jamMulaiDefault =
        scheduleData.isNotEmpty ? scheduleData[0]["start"] : '';
    String jamSelesaiDefault =
        scheduleData.isNotEmpty ? scheduleData[0]["end"] : '';

    return Jadwal(
      id: json['id'] ?? 0,
      mataPelajaran: mataPelajaranValue,
      kelas: kelasValue,
      guru: guruValue,
      idMapel: json['subject_id'] ?? 0,
      scheduleData: scheduleData,
      hari: hariDefault,
      jamMulai: jamMulaiDefault,
      jamSelesai: jamSelesaiDefault,
    );
  }

  // Membuat daftar jadwal terpisah untuk setiap hari
  List<Jadwal> expandToMultiDay() {
    List<Jadwal> jadwalList = [];

    // Pastikan scheduleData tidak kosong
    if (scheduleData.isEmpty) {
      return [this]; // Kembalikan jadwal asli jika tidak ada data multi-hari
    }

    // Buat satu objek Jadwal untuk setiap hari dalam jadwal
    for (var schedule in scheduleData) {
      jadwalList.add(Jadwal(
        id: this.id,
        mataPelajaran: this.mataPelajaran,
        kelas: this.kelas,
        guru: this.guru,
        idMapel: this.idMapel,
        scheduleData: this.scheduleData,
        hari: schedule["day"] ?? "Unknown",
        jamMulai: schedule["start"] ?? "",
        jamSelesai: schedule["end"] ?? "",
      ));
    }

    return jadwalList;
  }
}
