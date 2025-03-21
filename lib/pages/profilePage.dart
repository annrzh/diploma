import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authPage.dart'; // Импортируем страницу авторизации

class profilePage extends StatelessWidget {
  final String userId;

  const profilePage({super.key, required this.userId});

  // Метод для выхода из аккаунта
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId'); // Удаляем userId при выходе
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const authPage(), // Переход на страницу авторизации
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Личный кабинет'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Добро пожаловать, пользователь с ID: $userId',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context), // Выход из аккаунта
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
