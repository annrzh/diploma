import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class catManPage extends StatefulWidget {
  const catManPage({super.key});

  @override
  _catManPageState createState() => _catManPageState();
}

class _catManPageState extends State<catManPage> {
  final TextEditingController _nameController = TextEditingController();
  String _errorMessage = '';
  String _successMessage = '';

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();

    // Очистка сообщений
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Введите название категории!';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://26.171.234.69:3001/api/categories'), // Адрес сервера
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 201) {
        setState(() {
          _successMessage = 'Категория добавлена!';
          _nameController.clear();
        });
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Ошибка добавления категории.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу. Проверьте соединение.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление категориями')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название категории'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Добавить категорию'),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ],
            if (_successMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_successMessage, style: const TextStyle(color: Colors.green)),
            ],
          ],
        ),
      ),
    );
  }
}
