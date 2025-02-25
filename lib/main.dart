import 'package:flutter/material.dart';
import 'login.dart';
import 'halaman_activity.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi E-Saturasi',
      home: HalamanActivity(),
    );
  }
}
