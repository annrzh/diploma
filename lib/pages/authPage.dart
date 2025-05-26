import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profilePage.dart'; // Импортируем страницу личного кабинета

class authPage extends StatefulWidget {
  const authPage({super.key});

  @override
  _authPageState createState() => _authPageState();
}

class _authPageState extends State<authPage> {
  bool isLogin = false; // По умолчанию - регистрация
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  String _successMessage = '';

  Future<void> _handleAuth() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final telephone = _telephoneController.text.trim();
    final password = _passwordController.text.trim();

    // Очистка сообщений
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (!isLogin) {
      // Регистрация
      if (name.isEmpty ||
          email.isEmpty ||
          telephone.isEmpty ||
          password.isEmpty) {
        setState(() {
          _errorMessage = 'Заполните все поля!';
        });
        return;
      }

      try {
        final response = await http.post(
          Uri.parse(
              'http://26.171.234.69:3001/api/register'), // Используем IP вашего компьютера для подключения
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'telephone': telephone,
            'password': password,
          }),
        );

        if (response.statusCode == 201) {
          setState(() {
            isLogin = true;
            _successMessage = 'Регистрация прошла успешно! Теперь войдите.';
          });
        } else {
          final responseData = jsonDecode(response.body);
          setState(() {
            _errorMessage = responseData['message'] ?? 'Ошибка регистрации.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Ошибка подключения к серверу. Проверьте соединение.';
        });
      }
    } else {
      // Логика входа
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Введите Email и пароль!';
        });
        return;
      }

      try {
        final response = await http.post(
          Uri.parse(
              'http://26.171.234.69:3001/api/login'), // Используем IP вашего компьютера для подключения
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          // Сохраняем userId и флаг isLoggedIn в SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true); // <--- добавлено
          await prefs.setString('userId', responseData['userId'].toString());

          setState(() {
            _successMessage =
                'Добро пожаловать, пользователь ID: ${responseData['userId']}';
          });

          // Переход к личному кабинету
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => profilePage(
                  userId: responseData['userId']
                      .toString()), // Передаем userId на страницу профиля
            ),
          );
        } else {
          final responseData = jsonDecode(response.body);
          setState(() {
            _errorMessage = responseData['message'] ?? 'Ошибка входа.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Ошибка подключения к серверу. Проверьте соединение.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Вход' : 'Регистрация'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isLogin)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Имя'),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (!isLogin)
              TextField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Телефон'),
                keyboardType: TextInputType.phone,
              ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleAuth,
              child: Text(isLogin ? 'Войти' : 'Зарегистрироваться'),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_successMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _successMessage,
                style: const TextStyle(color: Colors.green),
              ),
            ],
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                  _errorMessage = '';
                  _successMessage = '';
                });
              },
              child: Text(isLogin
                  ? 'Нет аккаунта? Зарегистрироваться'
                  : 'Уже есть аккаунт? Войти'),
            ),
          ],
        ),
      ),
    );
  }
}
