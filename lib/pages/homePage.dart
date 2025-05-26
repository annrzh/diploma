import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'authPage.dart';
import 'profilePage.dart';
import 'admin.dart';
import 'cartsPage.dart';
import 'searchPage.dart';

class homePage extends StatefulWidget {
  const homePage({super.key, required this.title});

  final String title;

  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  final String _baseUrl = 'http://26.171.234.69:3001/api/products/cards';

  bool isLoggedIn = false;
  String userId = '';
  List<dynamic> products = [];
  bool isLoading = true;
  String _errorMessage = '';
  int _currentIndex = 0; // текущая выбранная вкладка

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchProducts();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      userId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print(' Response status: ${response.statusCode}');
      print(' Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          setState(() {
            products = decoded;
            isLoading = false;
            _errorMessage = '';
          });
        } else {
          setState(() {
            _errorMessage = 'Неверный формат данных от сервера.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Ошибка сервера: ${response.statusCode}\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _addToCart(String productId) async {
    if (userId.isEmpty) {
      // Если не залогинен, предложить войти
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Пожалуйста, войдите в личный кабинет, чтобы добавлять товары в корзину.')),
      );
      return;
    }

    final url = Uri.parse('http://26.171.234.69:3001/api/cart/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'productId': productId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар добавлен в корзину')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка добавления товара: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка подключения: $e')),
      );
    }
  }

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
        _checkLoginStatus();
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const authPage(),
        ),
      ).then((_) {
        _checkLoginStatus();
      });
    }
  }

  void _navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Admin()),
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');

    setState(() {
      isLoggedIn = false;
      userId = '';
    });

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const authPage()),
        (route) => false,
      );
    }
  }

  Widget _buildProductCard(dynamic product) {
    final name = product['name']?.toString() ?? 'Без названия';
    final article = product['article']?.toString() ?? 'нет';
    final price = product['product_cost']?.toString() ?? '-';
    final productId = product['id']?.toString() ?? '';

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text('Артикул: $article', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text('Цена: $price ₽', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _addToCart(productId),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.add_shopping_cart,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
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
              Scaffold.of(context).openDrawer();
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
                        Navigator.pop(context);
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const cartsPage()),
                );
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
            if (isLoggedIn) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Выйти'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Администратор'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAdmin();
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : products.isEmpty
                  ? const Center(
                      child: Text(
                      'Нет доступных товаров.',
                      style: TextStyle(fontSize: 16),
                    ))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _buildProductCard(product);
                        },
                      ),
                    ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white, // Цвет выбранной иконки и текста
        unselectedItemColor: Colors.white70, // Цвет невыбранных иконок и текста
        backgroundColor: Colors.green, // ЗЕЛЁНЫЙ ФОН
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              // Уже на homePage
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const searchPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const cartsPage()),
              );
              break;
            case 3:
              _navigateToProfile();
              break;
          }
        },
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
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
