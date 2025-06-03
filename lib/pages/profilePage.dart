import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authPage.dart'; // Импорт страницы авторизации

class profilePage extends StatelessWidget {
  final String userId;

  const profilePage({super.key, required this.userId});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const authPage(),
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
              onPressed: () => _logout(context),
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
