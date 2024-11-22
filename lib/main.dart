// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shew/screens/home.dart';
import 'package:shew/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDB();
  runApp(const ShewApp());
}

class ShewApp extends StatelessWidget {
  const ShewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter List Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ShewHomePage(),
    );
  }
}
