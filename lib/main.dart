import 'package:flutter/material.dart';
import 'pages/homePage.dart'; // Главная страница

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const homePage(title: 'Главная страница'), // Главная страница запускается по умолчанию
    );
  }
}
