import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authPage.dart'; // Импортируем страницу авторизации
import 'profilePage.dart'; // Импортируем личный кабинет
import 'admin.dart'; // Импортируем страницу администратора

class homePage extends StatefulWidget {
  const homePage({super.key, required this.title});

  final String title;

  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  bool isLoggedIn = false;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Проверяем статус входа
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      userId = prefs.getString('userId') ?? '';
    });
  }

  // Переход на "Личный кабинет" или "Авторизацию"
  void _navigateToProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final storedUserId = prefs.getString('userId') ?? '';

    if (loggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => profilePage(userId: storedUserId),
        ),
      ).then((_) {
        _checkLoginStatus(); // Обновляем статус входа
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const authPage(),
        ),
      ).then((_) {
        _checkLoginStatus(); // Обновляем статус после авторизации
      });
    }
  }

  // Переход на экран администратора
  void _navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Admin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(widget.title),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Открыть боковое меню
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 89,
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Меню',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Закрыть меню
                      },
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Поиск'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Корзина'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Личный кабинет'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile();
              },
            ),
            const Divider(), // Разделитель
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Администратор'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAdmin(); // Переход в панель администратора
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: isLoggedIn
            ? Text('Добро пожаловать, пользователь $userId!')
            : const Text('Пожалуйста, авторизуйтесь'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Поиск',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Корзина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Личный кабинет',
          ),
        ],
        onTap: (index) {
          if (index == 3) {
            _navigateToProfile();
          }
        },
      ),
    );
  }
}
