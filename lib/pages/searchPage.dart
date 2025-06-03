import 'package:flutter/material.dart';

class searchPage extends StatefulWidget {
  const searchPage({super.key});

  @override
  State<searchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<searchPage> {
  final int _currentIndex = 1; // Поиск — второй пункт, индекс 1

  void _onTap(int index) {
    if (index == _currentIndex) return; // уже здесь — не делаем ничего

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/homePage');
        break;
      case 1:
        // Поиск — мы уже здесь
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/cartsPage');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/accountPage');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Убирает стрелку назад
      ),
      body: const Center(
        child: Text(
          'Здесь будет поиск товаров',
          style: TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.green,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Корзина'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
