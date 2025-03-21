import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CarManPage extends StatefulWidget {
  const CarManPage({super.key});

  @override
  _CarManPageState createState() => _CarManPageState();
}

class _CarManPageState extends State<CarManPage> {
  List<dynamic> marks = [];
  List<dynamic> models = [];
  bool isLoadingMarks = true;
  bool isLoadingModels = true;

  @override
  void initState() {
    super.initState();
    _loadMarks();
    _loadModels();
  }
Future<void> _loadMarks() async {
  setState(() {
    isLoadingMarks = true;
  });
  final response = await http.get(Uri.parse('http://127.0.0.1:3001/api/marks')); // Исправил URL
  if (response.statusCode == 200) {
    setState(() {
      marks = json.decode(response.body);
      isLoadingMarks = false;
    });
  } else {
    setState(() {
      isLoadingMarks = false;
    });
    _showError('Ошибка при загрузке марок.');
  }
}

Future<void> _loadModels() async {
  setState(() {
    isLoadingModels = true;
  });
  final response = await http.get(Uri.parse('http://127.0.0.1:3001/api/models')); // Исправил URL
  if (response.statusCode == 200) {
    setState(() {
      models = json.decode(response.body);
      isLoadingModels = false;
    });
  } else {
    setState(() {
      isLoadingModels = false;
    });
    _showError('Ошибка при загрузке моделей.');
  }
}

Future<void> addMark(String name) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:3001/api/marks'), // Исправил URL
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'name': name}),
  );

  if (response.statusCode == 201) {
    // Если запрос успешен
    print('Марка успешно добавлена');
  } else {
    // Если произошла ошибка
    print('Ошибка добавления марки: ${response.body}');
  }
}

Future<void> addModel(String name, int year, int markId) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:3001/api/models'), // Исправил URL
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'name': name,
      'year_of_release': year,
      'mark_id': markId,
    }),
  );

  if (response.statusCode == 200) {
    _loadModels();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Модель успешно добавлена!')),
    );
  } else {
    _showError('Ошибка при добавлении модели.');
  }
}

Future<void> updateMark(int id, String newName) async {
  final response = await http.put(
    Uri.parse('http://127.0.0.1:3001/api/marks/$id'), // Исправил URL
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'name': newName}),
  );

  if (response.statusCode == 200) {
    _loadMarks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Марка успешно обновлена!')),
    );
  } else {
    _showError('Ошибка при обновлении марки.');
  }
}

Future<void> updateModel(int id, String newName, int newYear, int newMarkId) async {
  final response = await http.put(
    Uri.parse('http://127.0.0.1:3001/api/models/$id'), // Исправил URL
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'name': newName,
      'year_of_release': newYear,
      'mark_id': newMarkId,
    }),
  );

  if (response.statusCode == 200) {
    _loadModels();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Модель успешно обновлена!')),
    );
  } else {
    _showError('Ошибка при обновлении модели.');
  }
}

Future<void> deleteMark(int id) async {
  final response = await http.delete(
    Uri.parse('http://127.0.0.1:3001/api/marks/$id'), // Исправил URL
  );

  if (response.statusCode == 200) {
    _loadMarks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Марка успешно удалена!')),
    );
  } else {
    _showError('Ошибка при удалении марки.');
  }
}

Future<void> deleteModel(int id) async {
  final response = await http.delete(
    Uri.parse('http://127.0.0.1:3001/api/models/$id'), // Исправил URL
  );

  if (response.statusCode == 200) {
    _loadModels();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Модель успешно удалена!')),
    );
  } else {
    _showError('Ошибка при удалении модели.');
  }
}


  void _showAddMarkForm() {
    final _formKey = GlobalKey<FormState>();
    final _markController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить марку автомобиля'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _markController,
              decoration: const InputDecoration(labelText: 'Название марки'),
              validator: (value) => value == null || value.isEmpty ? 'Введите название' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await addMark(_markController.text);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  void _showAddModelForm() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _yearController = TextEditingController();
    int? selectedMarkId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить модель автомобиля'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Выберите марку'),
                  items: marks.map<DropdownMenuItem<int>>((mark) {
                    return DropdownMenuItem<int>(
                      value: mark['id'],
                      child: Text(mark['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMarkId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Выберите марку' : null,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Название модели'),
                  validator: (value) => value == null || value.isEmpty ? 'Введите название' : null,
                ),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(labelText: 'Год выпуска'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите год';
                    if (int.tryParse(value) == null) return 'Некорректный год';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() && selectedMarkId != null) {
                  await addModel(
                    _nameController.text,
                    int.parse(_yearController.text),
                    selectedMarkId!,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Управление автомобилями',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Марки автомобилей',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isLoadingMarks)
                  const Center(child: CircularProgressIndicator())
                else if (marks.isEmpty)
                  const Center(child: Text('Нет данных о марках'))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: marks.length,
                      itemBuilder: (context, index) {
                        final mark = marks[index];
                        return ListTile(
                          title: Text(mark['name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showUpdateMarkForm(mark['id'], mark['name']);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteMark(mark['id']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ElevatedButton(
                  onPressed: _showAddMarkForm,
                  child: const Text('Добавить марку'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Модели автомобилей',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isLoadingModels)
                  const Center(child: CircularProgressIndicator())
                else if (models.isEmpty)
                  const Center(child: Text('Нет данных о моделях'))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: models.length,
                      itemBuilder: (context, index) {
                        final model = models[index];
                        return ListTile(
                          title: Text(model['name']),
                          subtitle: Text('Год выпуска: ${model['year_of_release']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showUpdateModelForm(
                                    model['id'],
                                    model['name'],
                                    model['year_of_release'],
                                    model['mark_id'],
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteModel(model['id']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ElevatedButton(
                  onPressed: _showAddModelForm,
                  child: const Text('Добавить модель'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateMarkForm(int id, String currentName) {
    final _formKey = GlobalKey<FormState>();
    final _markController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Обновить марку автомобиля'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _markController,
              decoration: const InputDecoration(labelText: 'Название марки'),
              validator: (value) => value == null || value.isEmpty ? 'Введите название' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await updateMark(id, _markController.text);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Обновить'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateModelForm(int id, String currentName, int currentYear, int currentMarkId) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: currentName);
    final _yearController = TextEditingController(text: currentYear.toString());
    int? selectedMarkId = currentMarkId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Обновить модель автомобиля'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedMarkId,
                  decoration: const InputDecoration(labelText: 'Выберите марку'),
                  items: marks.map<DropdownMenuItem<int>>((mark) {
                    return DropdownMenuItem<int>(
                      value: mark['id'],
                      child: Text(mark['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMarkId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Выберите марку' : null,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Название модели'),
                  validator: (value) => value == null || value.isEmpty ? 'Введите название' : null,
                ),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(labelText: 'Год выпуска'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите год';
                    if (int.tryParse(value) == null) return 'Некорректный год';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() && selectedMarkId != null) {
                  await updateModel(
                    id,
                    _nameController.text,
                    int.parse(_yearController.text),
                    selectedMarkId!,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Обновить'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }
}
