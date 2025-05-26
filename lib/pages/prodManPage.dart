import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:application/pages/addProdPage.dart';
import 'package:http/http.dart' as http;

class ProdManPage extends StatefulWidget {
  const ProdManPage({super.key});

  @override
  _ProdManPageState createState() => _ProdManPageState();
}

class _ProdManPageState extends State<ProdManPage> {
  List<dynamic> _products = [];
  String _errorMessage = '';

  final String _baseUrl = 'http://26.171.234.69:3001/api/products';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _products = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка загрузки товаров';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу.';
      });
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _fetchProducts();
      } else {
        setState(() {
          _errorMessage = 'Ошибка удаления товара';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при удалении';
      });
    }
  }

 Future<void> _editProduct(Map<String, dynamic> product) async {
  final nameController = TextEditingController(text: product['name']);
  final articleController = TextEditingController(text: product['article']);
  final costController = TextEditingController(text: product['product_cost']?.toString());
  final weightController = TextEditingController(text: product['product_weight']?.toString());
  final availability = product['availability'] ?? 'есть в наличии';

  String selectedAvailability = availability;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Редактировать товар'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: articleController,
              decoration: const InputDecoration(labelText: 'Артикул'),
            ),
            TextField(
              controller: costController,
              decoration: const InputDecoration(labelText: 'Стоимость'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Вес'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: selectedAvailability,
              decoration: const InputDecoration(labelText: 'Наличие'),
              items: const [
                DropdownMenuItem(value: 'есть в наличии', child: Text('есть в наличии')),
                DropdownMenuItem(value: 'нет в наличии', child: Text('нет в наличии')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedAvailability = value;
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () async {
            final updatedProduct = {
              'name': nameController.text.trim(),
              'article': articleController.text.trim(),
              'product_cost': double.tryParse(costController.text) ?? 0,
              'product_weight': double.tryParse(weightController.text) ?? 0,
              'availability': selectedAvailability,
            };

            try {
              final response = await http.put(
                Uri.parse('$_baseUrl/${product['id']}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(updatedProduct),
              );

              if (response.statusCode == 200) {
                Navigator.of(context).pop();
                _fetchProducts();
              } else {
                setState(() {
                  _errorMessage = 'Ошибка обновления товара';
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

  void _navigateToAddProduct() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AddProdPage()),
  );
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Зелёный заголовок с кнопкой назад и добавления
          Container(
            color: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Управление товарами',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _navigateToAddProduct,
                ),
              ],
            ),
          ),

          // Таблица с заголовками
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Название', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Артикул', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Действия', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(),

          // Список товаров
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text('Нет товаров для отображения'))
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(product['name'] ?? 'Без названия')),
                            Expanded(flex: 2, child: Text(product['article'] ?? '—')),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editProduct(product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteProduct(product['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Сообщение об ошибке
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
