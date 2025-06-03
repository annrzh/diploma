// lib/main.dart
import 'package:flutter/material.dart';
// Убедитесь, что пути к вашим файлам страниц верны
import 'pages/homepage.dart'; // Ожидается: class homePage
import 'pages/searchpage.dart'; // Ожидается: class searchPage
// import 'pages/cartspage.dart'; // Больше не нужен здесь для 'routes'
import 'pages/authpage.dart'; // Ожидается: class authPage
// profilePage и admin будут вызываться через Navigator.push из homePage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo', // Можете изменить на название вашего приложения
      theme: ThemeData(
          primarySwatch: Colors.green, // Основной цвет вашего приложения
          appBarTheme: const AppBarTheme(
            // Стили для AppBar по умолчанию
            backgroundColor: Colors.green,
            foregroundColor: Colors.white, // Цвет текста и иконок
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            // Стили для ElevatedButton
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            // Стили для BottomNavigationBar
            backgroundColor: Colors.green,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            type: BottomNavigationBarType.fixed,
          )),
      // initialRoute определяет, какая страница будет загружена первой,
      // если home не указан. homePage сама проверит, вошел ли пользователь.
      initialRoute: '/homePage',
      routes: {
        // Маршруты для страниц, которые НЕ требуют динамических аргументов в конструкторе
        // при их вызове по имени.
        '/homePage': (context) => const homePage(title: 'Главная страница'),
        '/searchPage': (context) => const searchPage(),
        '/authPage': (context) => const authPage(),
        // '/cartsPage': (context) => const cartsPage(), // <-- ЭТУ СТРОКУ НУЖНО УДАЛИТЬ ИЛИ ЗАКОММЕНТИРОВАТЬ
        // так как cartsPage теперь требует userId,
        // и навигация на нее идет из homePage
      },
      // Если вам понадобится передавать аргументы через именованные маршруты для других страниц,
      // вы можете использовать onGenerateRoute, но для cartsPage и profilePage мы используем
      // MaterialPageRoute с прямой передачей аргументов из homePage.
    );
  }
}
