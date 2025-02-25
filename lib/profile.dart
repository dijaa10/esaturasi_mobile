import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text(
          "Ini Halaman Profile",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
