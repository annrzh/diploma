import 'package:flutter/material.dart';
import 'addProdPage.dart'; // Импорт нового экрана

class ProdManPage extends StatelessWidget {
  const ProdManPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Управление товарами', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProdPage()),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Страница управления товарами')),
    );
  }
}
