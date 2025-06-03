// lib/pages/homepage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Ваши импорты (убедитесь, что имена файлов и КЛАССОВ внутри них соответствуют):
import 'authPage.dart'; // Ожидается: class authPage
import 'profilePage.dart'; // Ожидается: class profilePage (принимает String userId)
import 'admin.dart'; // Ожидается: class admin
import 'cartsPage.dart'; // Ожидается: class cartsPage (принимает int userId)
import 'searchPage.dart'; // Ожидается: class searchPage

class homePage extends StatefulWidget {
  final String title;
  const homePage({super.key, required this.title});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<homePage> {
  // ЗАМЕНИТЕ НА ВАШИ АКТУАЛЬНЫЕ URL СЕРВЕРА
  final String _productsBaseUrl = 'http://10.0.2.2:3001/api/products/cards';
  final String _cartApiUrl = 'http://10.0.2.2:3001/api/cart';

  bool isLoggedIn = false;
  int? userId;
  List<dynamic> products = [];
  bool _isLoadingProducts = true;
  String _productErrorMessage = '';
  int _currentIndex = 0;
  String _userEmailForDrawer = 'Пожалуйста, войдите';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _checkLoginStatus();
    if (isLoggedIn) {
      _fetchProducts();
    } else {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? storedUserId = prefs.getInt('userId');
    final bool storedIsLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    // final String? storedUserEmail = prefs.getString('userEmail');

    if (mounted) {
      setState(() {
        isLoggedIn = storedIsLoggedIn && storedUserId != null;
        userId = isLoggedIn ? storedUserId : null;
        // _userEmailForDrawer = isLoggedIn && storedUserEmail != null ? storedUserEmail : 'Пожалуйста, войдите';
      });
    }
    print(
        "homePage _checkLoginStatus: isLoggedIn = $isLoggedIn, userId = $userId");
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
      _productErrorMessage = '';
    });
    try {
      final response = await http.get(Uri.parse(_productsBaseUrl),
          headers: {'Content-Type': 'application/json'});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          if (mounted) setState(() => products = decoded);
        } else {
          if (mounted)
            setState(() => _productErrorMessage =
                'Неверный формат ответа от сервера (товары).');
        }
      } else {
        if (mounted)
          setState(() => _productErrorMessage =
              'Ошибка загрузки товаров: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted)
        setState(() =>
            _productErrorMessage = 'Сетевая ошибка при загрузке товаров.');
      print('[_fetchProducts] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _addToCart(String productIdString) async {
    if (!mounted) return;
    if (userId == null) {
      _showSnackbar('Пожалуйста, войдите, чтобы добавить товар в корзину.');
      return;
    }
    int? parsedProductId = int.tryParse(productIdString);
    if (parsedProductId == null) {
      _showSnackbar("Ошибка: некорректный ID товара ($productIdString).",
          isError: true);
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(_cartApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'user_id': userId, 'product_id': parsedProductId, 'quantity': 1}),
      );
      if (!mounted) return;
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar(responseData['message'] ?? 'Товар добавлен в корзину!');
      } else {
        _showSnackbar(
            responseData['message'] ??
                'Ошибка добавления товара: ${response.statusCode}',
            isError: true);
      }
    } catch (e) {
      if (mounted)
        _showSnackbar('Сетевая ошибка при добавлении в корзину.',
            isError: true);
      print('Error _addToCart: $e');
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? Colors.redAccent
          : Theme.of(context).snackBarTheme.backgroundColor,
      duration: const Duration(seconds: 3),
    ));
  }

  // ИЗМЕНЕННЫЙ МЕТОД _handleBottomNavTap (без pageToNavigate)
  void _handleBottomNavTap(int index) {
    if (!mounted) return;
    if (_currentIndex == index && index != 0) return;
    if (_currentIndex == index && index == 0) {
      // Повторный тап на "Главная"
      if (isLoggedIn) _fetchProducts();
      return;
    }

    setState(() => _currentIndex =
        index); // Устанавливаем новый индекс для UI BottomNavigationBar

    switch (index) {
      case 0: // Главная
        if (isLoggedIn) _fetchProducts();
        // Для case 0 навигация не нужна, мы остаемся на главной
        break;
      case 1: // Поиск
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const searchPage()) // Используем класс searchPage
            ).then((_) => _onReturnFromOtherPage());
        break;
      case 2: // Корзина
        if (isLoggedIn && userId != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      cartsPage(userId: userId!)) // Используем класс cartsPage
              ).then((_) => _onReturnFromOtherPage());
        } else {
          _showSnackbar('Пожалуйста, войдите, чтобы открыть корзину.');
          _navigateToProfilePage(); // Этот метод сам выполнит навигацию (на authPage, если не залогинен)
        }
        break;
      case 3: // Профиль
        _navigateToProfilePage(); // Этот метод сам выполнит навигацию
        break;
    }
  }

  void _navigateToProfilePage() async {
    if (!mounted) return;
    if (isLoggedIn && userId != null) {
      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => profilePage(
                      userId:
                          userId.toString()))) // Используем класс profilePage
          .then((_) => _onReturnFromOtherPage());
    } else {
      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const authPage())) // Используем класс authPage
          .then((_) => _onReturnFromOtherPage());
    }
  }

  void _navigateToAdminPage() {
    if (!mounted) return;
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const admin())) // Используем класс admin
        .then((_) => _onReturnFromOtherPage());
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const authPage()), // Используем класс authPage
        (route) => false,
      );
    }
  }

  void _onReturnFromOtherPage() {
    if (mounted) {
      print("Возврат на homePage. Обновляем статус входа.");
      _checkLoginStatus();
      // Если после возврата с другой страницы вы хотите, чтобы активной вкладкой
      // всегда становилась "Главная", раскомментируйте следующую строку:
      // setState(() => _currentIndex = 0);
      // В текущей реализации _currentIndex не меняется при возврате,
      // оставаясь на той вкладке, с которой был совершен переход.
    }
  }

  Widget _buildProductCard(dynamic product) {
    final name = product['name']?.toString() ?? 'Без названия';
    final price = product['product_cost']?.toString() ?? '-';
    final productIdString = product['id']?.toString();

    if (productIdString == null ||
        productIdString.isEmpty ||
        productIdString.toLowerCase() == "null") {
      print(
          'Пропуск карточки товара: ID товара ($productIdString) невалиден для продукта: $name');
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print("Нажата карточка товара: $name (ID: $productIdString)");
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: Icon(Icons.image_not_supported_outlined,
                    size: 40, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$price BYN',
                    style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.add_shopping_cart,
                          color: Colors.deepOrangeAccent),
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: () => _addToCart(productIdString),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (isLoggedIn)
                _fetchProducts();
              else
                _showSnackbar("Войдите для обновления товаров.");
            },
            tooltip: 'Обновить товары',
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.primaryColor),
              accountName: Text(isLoggedIn && userId != null
                  ? 'Пользователь #$userId'
                  : 'Гость'),
              accountEmail: Text(_userEmailForDrawer),
            ),
            ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Главная'),
                onTap: () {
                  Navigator.pop(context);
                  _handleBottomNavTap(0);
                }),
            ListTile(
                leading: const Icon(Icons.search_outlined),
                title: const Text('Поиск'),
                onTap: () {
                  Navigator.pop(context);
                  _handleBottomNavTap(1);
                }),
            ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Корзина'),
                onTap: () {
                  Navigator.pop(context);
                  _handleBottomNavTap(2);
                }),
            ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Профиль'),
                onTap: () {
                  Navigator.pop(context);
                  _handleBottomNavTap(3);
                }),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Админ'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAdminPage();
                }),
            if (isLoggedIn)
              ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('Выйти'),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  }),
          ],
        ),
      ),
      body: !isLoggedIn
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.login_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                      'Для доступа к функциям приложения, пожалуйста, войдите.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const authPage()), // Используем класс authPage
                      );
                    },
                    child: const Text('Войти / Зарегистрироваться'),
                  )
                ],
              ),
            ))
          : _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : _productErrorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_productErrorMessage,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 16),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              TextButton(
                                  onPressed: _fetchProducts,
                                  child: const Text("Попробовать снова"))
                            ],
                          )))
                  : products.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.layers_clear_outlined,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Товары не найдены.',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            TextButton(
                                onPressed: _fetchProducts,
                                child: const Text("Попробовать снова"))
                          ],
                        ))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: products.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Widget productCardWidget =
                                _buildProductCard(products[index]);
                            return productCardWidget;
                          },
                        ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
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
