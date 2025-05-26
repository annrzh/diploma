import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddProdPage extends StatefulWidget {
  const AddProdPage({super.key});

  @override
  _AddProdPageState createState() => _AddProdPageState();
}

class _AddProdPageState extends State<AddProdPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _articleController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _errorMessage = '';
  String _successMessage = '';

  final String _baseUrl = 'http://26.171.234.69:3001/api';
  List<dynamic> _categories = [];
  List<dynamic> _models = [];

  int? _selectedCategoryId;
  int? _selectedModelId;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchModels();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories'));
      if (response.statusCode == 200) {
        setState(() {
          _categories = jsonDecode(response.body);
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Не удалось загрузить категории';
      });
    }
  }

  Future<void> _fetchModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/models'));
      if (response.statusCode == 200) {
        setState(() {
          _models = jsonDecode(response.body);
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Не удалось загрузить модели';
      });
    }
  }

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final article = _articleController.text.trim();
    final cost = double.tryParse(_costController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (name.isEmpty || article.isEmpty || cost == null || weight == null || _selectedCategoryId == null || _selectedModelId == null) {
      setState(() {
        _errorMessage = 'Пожалуйста, заполните все поля корректно!';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'article': article,
          'product_cost': cost,
          'product_weight': weight,
          'category_id': _selectedCategoryId,
          'model_id': _selectedModelId,
          'availability': 'есть в наличии',
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _successMessage = 'Товар добавлен!';
          _nameController.clear();
          _articleController.clear();
          _costController.clear();
          _weightController.clear();
          _selectedCategoryId = null;
          _selectedModelId = null;
        });
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Ошибка добавления товара.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление товарами')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название товара'),
            ),
            TextField(
              controller: _articleController,
              decoration: const InputDecoration(labelText: 'Артикул товара'),
            ),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Стоимость товара'),
            ),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Вес товара'),
            ),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              items: _categories
                  .map((category) => DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(category['name']),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Категория'),
            ),
            DropdownButtonFormField<int>(
              value: _selectedModelId,
              items: _models
                  .map((model) => DropdownMenuItem<int>(
                        value: model['id'],
                        child: Text(model['name']),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedModelId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Модель'),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _addProduct,
                child: const Text('Добавить товар'),
              ),
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
