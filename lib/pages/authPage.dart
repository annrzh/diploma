import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profilePage.dart'; // Убедитесь, что имя файла и класса здесь profilePage

class authPage extends StatefulWidget {
  const authPage({super.key});

  @override
  _authPageState createState() => _authPageState();
}

class _authPageState extends State<authPage> {
  bool isLogin = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  String _successMessage = '';

  final String _baseUrl =
      'http://10.0.2.2:3001'; // ЗАМЕНИТЕ НА ВАШ АКТУАЛЬНЫЙ URL СЕРВЕРА

  Future<void> _handleAuth() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final telephone = _telephoneController.text.trim();
    final password = _passwordController.text.trim();

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
        setState(() => _errorMessage = 'Заполните все поля!');
        return;
      }
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/api/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'telephone': telephone,
            'password': password
          }),
        );
        if (!mounted) return;
        if (response.statusCode == 201) {
          setState(() {
            isLogin = true;
            _successMessage = 'Регистрация прошла успешно! Теперь войдите.';
            _nameController.clear();
            _telephoneController.clear();
            _passwordController
                .clear(); // Email можно оставить для удобства входа
          });
        } else {
          final responseData = jsonDecode(response.body);
          setState(() => _errorMessage = responseData['message'] ??
              'Ошибка регистрации. Код: ${response.statusCode}');
        }
      } catch (e) {
        if (mounted)
          setState(() =>
              _errorMessage = 'Ошибка подключения к серверу при регистрации.');
        print('Registration error: $e');
      }
    } else {
      // Логика входа
      if (email.isEmpty || password.isEmpty) {
        setState(() => _errorMessage = 'Введите Email и пароль!');
        return;
      }
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/api/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          dynamic rawUserId = responseData['userId'];
          int? parsedUserId;
          if (rawUserId is int)
            parsedUserId = rawUserId;
          else if (rawUserId is String)
            parsedUserId = int.tryParse(rawUserId);
          else if (rawUserId is double) parsedUserId = rawUserId.toInt();

          if (parsedUserId == null) {
            if (mounted)
              setState(() => _errorMessage =
                  'Ошибка получения ID пользователя от сервера.');
            print(
                'Login error: userId from server is null/invalid. Raw: ${responseData['userId']}');
            return;
          }
          final int userId = parsedUserId;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('userId', userId);
          if (mounted) {
            setState(() =>
                _successMessage = 'Добро пожаловать, пользователь ID: $userId');
            // Важно: profilePage должен принимать userId как String
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => profilePage(userId: userId.toString())),
            );
          }
        } else {
          final responseData = jsonDecode(response.body);
          if (mounted)
            setState(() => _errorMessage = responseData['message'] ??
                'Ошибка входа. Код: ${response.statusCode}');
        }
      } catch (e) {
        if (mounted)
          setState(
              () => _errorMessage = 'Ошибка подключения к серверу при входе.');
        print('Login error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Вход' : 'Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isLogin)
              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Имя')),
            if (!isLogin) const SizedBox(height: 12),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            if (!isLogin)
              TextField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(labelText: 'Телефон'),
                  keyboardType: TextInputType.phone),
            if (!isLogin) const SizedBox(height: 12),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _handleAuth,
                child: Text(isLogin ? 'Войти' : 'Зарегистрироваться')),
            if (_errorMessage.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center)),
            if (_successMessage.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(_successMessage,
                      style: const TextStyle(color: Colors.green),
                      textAlign: TextAlign.center)),
            TextButton(
              onPressed: () => setState(() {
                isLogin = !isLogin;
                _errorMessage = '';
                _successMessage = '';
              }),
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
