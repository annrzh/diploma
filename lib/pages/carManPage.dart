import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class carManPage extends StatefulWidget {
  const carManPage({super.key});

  @override
  _carManPageState createState() => _carManPageState();
}

class _carManPageState extends State<carManPage> {
  final TextEditingController _markController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  String _errorMessage = '';
  String _successMessage = '';
  List<dynamic> _marks = [];
  List<dynamic> _models = [];
  int? _selectedMarkId;

  @override
  void initState() {
    super.initState();
    _fetchMarks();
    _fetchModels();
  }

  Future<void> _fetchMarks() async {
    try {
      final response = await http.get(
        Uri.parse('http://26.171.234.69:3001/api/marks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _marks = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка загрузки марок';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу. Проверьте соединение.';
      });
    }
  }

  Future<void> _fetchModels() async {
    try {
      final response = await http.get(
        Uri.parse('http://26.171.234.69:3001/api/models'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _models = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка загрузки моделей';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу. Проверьте соединение.';
      });
    }
  }

  Future<void> _deleteMark(int id) async {
    final response = await http.delete(
      Uri.parse('http://26.171.234.69:3001/api/marks/$id'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _marks = _marks.where((mark) => mark['id'] != id).toList();
      });
    } else {
      setState(() {
        _errorMessage = 'Ошибка удаления марки';
      });
    }
  }

  Future<void> _editMark(int id, String currentName) async {
    final TextEditingController _editController =
        TextEditingController(text: currentName);
    String newName = currentName;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать марку'),
          content: TextField(
            controller: _editController,
            onChanged: (value) {
              newName = value;
            },
            decoration: const InputDecoration(labelText: 'Название марки'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final response = await http.put(
                  Uri.parse('http://26.171.234.69:3001/api/marks/$id'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'name': newName}),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    _fetchMarks();
                  });
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _errorMessage = 'Ошибка обновления марки';
                  });
                }
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMark() async {
    final name = _markController.text.trim();

    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Введите название марки!';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://26.171.234.69:3001/api/marks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 201) {
        setState(() {
          _successMessage = 'Марка добавлена!';
          _markController.clear();
          _fetchMarks();
        });
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Ошибка добавления марки.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу. Проверьте соединение.';
      });
    }
  }

  Future<void> _addModel() async {
    final name = _modelController.text.trim();
    final yearText = _yearController.text.trim();

    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (name.isEmpty || yearText.isEmpty || _selectedMarkId == null) {
      setState(() {
        _errorMessage =
            'Введите название модели, год выпуска и выберите марку!';
      });
      return;
    }

    int? year = int.tryParse(yearText);
    if (year == null) {
      setState(() {
        _errorMessage = 'Год должен быть числом!';
      });
      return;
    }

    // Находим название марки по ID
    final selectedMark = _marks.firstWhere((mark) => mark['id'] == _selectedMarkId);
    final markName = selectedMark['name'];  // Получаем название марки

    try {
      final response = await http.post(
        Uri.parse('http://26.171.234.69:3001/api/models'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'year_of_release': year,
          'mark_name': markName,  // Отправляем mark_name, а не mark_id
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _successMessage = 'Модель добавлена!';
          _modelController.clear();
          _yearController.clear();
          _selectedMarkId = null;
        });
        _fetchModels(); // Обновляем список моделей
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              responseData['message'] ?? 'Ошибка добавления модели.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу. Проверьте соединение.';
      });
    }
  }

  Future<void> _editModel(int id, String currentName, int currentYear, int currentMarkId) async {
  final TextEditingController _editNameController = TextEditingController(text: currentName);
  final TextEditingController _editYearController = TextEditingController(text: currentYear.toString());

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Редактировать модель'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editNameController,
              decoration: const InputDecoration(labelText: 'Название модели'),
            ),
            TextField(
              controller: _editYearController,
              decoration: const InputDecoration(labelText: 'Год выпуска'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newYear = int.tryParse(_editYearController.text);
              if (newYear == null) {
                setState(() {
                  _errorMessage = 'Год должен быть числом!';
                });
                return;
              }

              final response = await http.put(
                Uri.parse('http://26.171.234.69:3001/api/models/$id'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'name': _editNameController.text,
                  'year_of_release': newYear,
                  'mark_id': currentMarkId
                }),
              );

              if (response.statusCode == 200) {
                setState(() {
                  _fetchModels();
                });
                Navigator.pop(context);
              } else {
                setState(() {
                  _errorMessage = 'Ошибка обновления модели';
                });
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      );
    },
  );
}


  Future<void> _deleteModel(int id) async {
    final response = await http.delete(
      Uri.parse('http://26.171.234.69:3001/api/models/$id'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _models = _models.where((model) => model['id'] != id).toList();
      });
    } else {
      setState(() {
        _errorMessage = 'Ошибка удаления модели';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление марками и моделями')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _marks.length,
                itemBuilder: (context, index) {
                  final mark = _marks[index];
                  return Card(
                    child: ListTile(
                      title: Text(mark['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editMark(mark['id'], mark['name']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteMark(mark['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _markController,
              decoration: const InputDecoration(labelText: 'Название марки'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addMark,
              child: const Text('Добавить марку'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _models.length,
                itemBuilder: (context, index) {
                  final model = _models[index];
                  return Card(
                    child: ListTile(
                      title: Text(model['name']),
                      subtitle: Text('Год выпуска: ${model['year_of_release']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editModel(model['id'], model['name'], model['year_of_release'], model['mark_id']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteModel(model['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Название модели'),
            ),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Год выпуска'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<int>(
              value: _marks.any((mark) => mark['id'] == _selectedMarkId)
                  ? _selectedMarkId
                  : null,
              hint: const Text('Выберите марку'),
              items: _marks.map((mark) {
                return DropdownMenuItem<int>(
                  value: mark['id'],
                  child: Text(mark['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMarkId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addModel,
              child: const Text('Добавить модель'),
            ),
          ],
        ),
      ),
    );
  }
}
