import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'TEST OK ✅',
          style: TextStyle(fontSize: 32, color: Colors.black),
        ),
      ),
    ),
  ));
}
