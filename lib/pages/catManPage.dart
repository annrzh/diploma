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
  List<dynamic> _categories = [];

  // Укажите здесь IP вашего компьютера или хоста, на котором работает сервер
  final String _baseUrl = 'http://26.171.234.69:3001/api/categories';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Функция загрузки категорий
  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _categories = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка загрузки категорий';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу. Проверьте IP и порт.';
      });
    }
  }

  // Функция добавления новой категории
  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
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
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 201) {
        setState(() {
          _successMessage = 'Категория добавлена!';
          _nameController.clear();
        });
        _fetchCategories();
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Ошибка добавления категории.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу.';
      });
    }
  }

  // Функция удаления категории
  Future<void> _deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _fetchCategories();
      } else {
        setState(() {
          _errorMessage = 'Ошибка удаления категории';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения при удалении';
      });
    }
  }

  // Функция редактирования категории
  Future<void> _editCategory(int id, String currentName) async {
    final TextEditingController editController =
        TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать категорию'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Новое название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isEmpty) return;

              try {
                final response = await http.put(
                  Uri.parse('$_baseUrl/$id'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'name': newName}),
                );

                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  _fetchCategories();
                } else {
                  setState(() {
                    _errorMessage = 'Ошибка обновления категории';
                  });
                }
              } catch (e) {
                setState(() {
                  _errorMessage = 'Ошибка подключения при обновлении';
                });
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление категориями')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    child: ListTile(
                      title: Text(category['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black),
                            onPressed: () => _editCategory(category['id'], category['name']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.black),
                            onPressed: () => _deleteCategory(category['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
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
