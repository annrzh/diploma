import 'package:flutter/material.dart';

import 'prodManPage.dart';
import 'catManPage.dart';
import 'carManPage.dart';
import 'ordersAdmPage.dart';

class Admin extends StatelessWidget {
  const Admin({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> buttons = [
      {'title': 'Управление товарами', 'route': ProdManPage()},
      {'title': 'Управление категориями', 'route': catManPage()},
      {'title': 'Управление автомобилями', 'route': carManPage()},
      {'title': 'Заказы', 'route': OrdersAdmPage()},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Admin Page',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(buttons.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => buttons[index]['route']),
                  );
                },
                child: Text(
                  buttons[index]['title'],
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}