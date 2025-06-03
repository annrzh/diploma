import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class cartsPage extends StatefulWidget {
  final int userId;

  const cartsPage({
    super.key,
    required this.userId,
  });

  @override
  _CartsPageState createState() => _CartsPageState();
}

class _CartsPageState extends State<cartsPage> {
  List<Map<String, dynamic>> cartItems = [];
  bool _selectionMode = false; // Переименовал для ясности
  Set<int> _selectedCartItemIds =
      {}; // Храним ID записей в корзине (cart_item_id)
  bool _isLoading = true;
  String? _errorMessage;

  // ЗАМЕНИТЕ НА ВАШ АКТУАЛЬНЫЙ URL СЕРВЕРА, если он отличается от этого
  // Этот URL предполагает, что эндпоинт для GET /cart/{userId} и POST /cart
  final String _apiBaseUrl = 'http://26.171.234.69:3001'; // Базовый URL сервера

  @override
  void initState() {
    super.initState();
    print(
        'cartsPage initState: Загрузка корзины для пользователя ID: ${widget.userId}');
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Формируем URL для получения корзины пользователя
      final url = Uri.parse('$_apiBaseUrl/api/cart/${widget.userId}');
      print('Fetching cart items from: $url');
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cartItems = data
              .map<Map<String, dynamic>?>((item) {
                // Явно указываем тип для map
                if (item == null || item is! Map)
                  return null; // Пропускаем некорректные элементы

                // Строгое приведение типов с проверками
                final cartItemId = _parseInt(item['id']);
                final productId = _parseInt(item['product_id']);
                final quantity = _parseInt(item['quantity'] ?? item['amount']);
                final price = _parseDouble(item['price']);
                final name = item['name']?.toString() ?? 'Неизвестный товар';

                if (cartItemId == null ||
                    productId == null ||
                    quantity == null ||
                    price == null) {
                  print(
                      'Ошибка парсинга элемента корзины: id=$cartItemId, productId=$productId, quantity=$quantity, price=$price. Исходные данные: $item');
                  return null; // Пропускаем элемент, если ключевые поля невалидны
                }

                return {
                  'id': cartItemId, // ID записи в корзине (int)
                  'product_id': productId, // ID продукта (int)
                  'name': name, // Название товара (String)
                  'price': price, // Цена (double)
                  'quantity': quantity, // Количество (int)
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList(); // Отфильтровываем null элементы
        });
      } else {
        String errorMsg = 'Не удалось загрузить корзину.';
        try {
          final errorData = json.decode(response.body);
          errorMsg =
              errorData['message'] ?? 'Ошибка сервера: ${response.statusCode}';
        } catch (e) {
          errorMsg =
              'Ошибка сервера: ${response.statusCode}. Не удалось разобрать ответ.';
        }
        if (mounted) setState(() => _errorMessage = errorMsg);
        print(
            'Failed to load cart items: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted)
        setState(
            () => _errorMessage = 'Сетевая ошибка при загрузке корзины: $e');
      print('Error fetching cart items: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Вспомогательные функции для безопасного парсинга
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double)
      return value.toInt(); // Позволяем double быть преобразованным в int
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double get _totalPrice {
    final itemsToCalculate = _selectionMode && _selectedCartItemIds.isNotEmpty
        ? cartItems
            .where((item) => _selectedCartItemIds.contains(item['id'] as int))
        : cartItems;
    return itemsToCalculate.fold(0.0, (sum, item) {
      final price =
          item['price'] as double? ?? 0.0; // Уже double после парсинга
      final quantity = item['quantity'] as int? ?? 0; // Уже int после парсинга
      return sum + (price * quantity);
    });
  }

  void _toggleSelectionMode() {
    if (!mounted) return;
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedCartItemIds.clear();
    });
  }

  void _toggleItemSelected(int cartItemId) {
    if (!mounted) return;
    setState(() {
      if (_selectedCartItemIds.contains(cartItemId)) {
        _selectedCartItemIds.remove(cartItemId);
      } else {
        _selectedCartItemIds.add(cartItemId);
      }
    });
  }

  Future<void> _updateItemQuantity(int productId, int newQuantity) async {
    if (!mounted) return;
    // Сервер должен обработать quantity <= 0 как удаление
    // Оптимистичное обновление (можно добавить, если нужно, но перезагрузка надежнее)
    // final originalItems = List<Map<String, dynamic>>.from(cartItems);

    try {
      // Формируем URL для обновления/добавления/удаления товара в корзине
      final url = Uri.parse('$_apiBaseUrl/api/cart'); // POST на /api/cart
      print(
          'Updating cart item: POST to $url with userId: ${widget.userId}, productId: $productId, quantity: $newQuantity');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'product_id': productId,
          'quantity': newQuantity,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Сервер: количество/товар обновлен для productId: $productId');
        await _fetchCartItems(); // Перезагрузка для полной синхронизации
      } else {
        // setState(() => cartItems = originalItems); // Откат, если было оптимистичное обновление
        String errorMsg = 'Ошибка обновления корзины.';
        try {
          final errorData = json.decode(response.body);
          errorMsg =
              errorData['message'] ?? 'Ошибка сервера: ${response.statusCode}';
        } catch (e) {
          errorMsg =
              'Ошибка сервера: ${response.statusCode}. Не удалось разобрать ответ.';
        }
        _showErrorSnackbar(errorMsg);
        print(
            'Failed to update cart item quantity: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // setState(() => cartItems = originalItems); // Откат
      if (mounted) _showErrorSnackbar('Сетевая ошибка при обновлении: $e');
      print('Network error updating cart item quantity: $e');
    }
  }

  Future<void> _incrementQuantity(int productId, int currentQuantity) async {
    if (currentQuantity + 1 > 999) {
      // Пример ограничения
      _showErrorSnackbar('Максимум 999 шт.');
      return;
    }
    await _updateItemQuantity(productId, currentQuantity + 1);
  }

  Future<void> _decrementQuantity(int productId, int currentQuantity) async {
    // Отправляем (currentQuantity - 1). Если результат 0 или меньше, сервер должен удалить.
    await _updateItemQuantity(productId, currentQuantity - 1);
  }

  Future<void> _removeSelectedItems() async {
    if (_selectedCartItemIds.isEmpty || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Удалить ${_selectedCartItemIds.length} товар(ов)?'),
        content: const Text(
            'Вы уверены, что хотите удалить выбранные товары из корзины?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      List<Future<void>> futures = [];
      for (int cartItemId in _selectedCartItemIds) {
        final item = cartItems.firstWhere((it) => it['id'] == cartItemId,
            orElse: () => {});
        if (item.isNotEmpty && item['product_id'] != null) {
          futures.add(_updateItemQuantity(
              item['product_id'] as int, 0)); // Отправляем 0 для удаления
        }
      }
      try {
        await Future.wait(futures);
      } catch (e) {
        print("Ошибка при пакетном удалении (Future.wait): $e");
      }

      if (mounted) {
        setState(() {
          _selectedCartItemIds.clear();
          _selectionMode = false;
        });
        await _fetchCartItems(); // Перезагружаем для полной синхронизации, _isLoading установится в false
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Получаем текущую тему

    return Scaffold(
      appBar: AppBar(
        // backgroundColor и foregroundColor будут взяты из темы MaterialApp
        title: const Text('Корзина'),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed:
                    _selectedCartItemIds.isEmpty ? null : _removeSelectedItems,
                tooltip: "Удалить выбранные")
            : BackButton(
                onPressed: () =>
                    Navigator.canPop(context) ? Navigator.pop(context) : null,
              ),
        actions: [
          if (cartItems.isNotEmpty && !_isLoading)
            IconButton(
              icon: Icon(_selectionMode
                  ? Icons.check_circle
                  : Icons.edit_attributes_outlined),
              onPressed: _toggleSelectionMode,
              tooltip: _selectionMode ? 'Готово' : 'Выбрать товары',
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 15),
                        Text('$_errorMessage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить попытку'),
                          onPressed: _fetchCartItems,
                        ),
                        if (_errorMessage!.toLowerCase().contains("user id") ||
                            _errorMessage!.toLowerCase().contains("войдите"))
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/auth', (route) => false);
                            },
                            child: const Text('Перейти ко входу'),
                          )
                      ],
                    ),
                  ),
                )
              : cartItems.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        const Text('Ваша корзина пуста',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          bottom: 80), // Отступ для кнопки "Оформить"
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final bool isSelected =
                            _selectedCartItemIds.contains(item['id'] as int);
                        final price = item['price'] as double; // Уже double
                        final quantity = item['quantity'] as int; // Уже int
                        final itemTotalPrice = price * quantity;

                        return Card(
                          elevation: _selectionMode ? (isSelected ? 4 : 2) : 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: isSelected
                              ? theme.primaryColor.withOpacity(0.1)
                              : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: _selectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleItemSelected(item['id'] as int),
                                    activeColor: theme.primaryColor,
                                  )
                                : CircleAvatar(
                                    backgroundColor: theme.primaryColorLight
                                        .withOpacity(0.5),
                                    foregroundColor: theme.primaryColorDark,
                                    child: Text(
                                        item['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            "?",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                            title: Text(item['name'] ?? 'Нет имени',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${price.toStringAsFixed(2)} BYN x $quantity шт.\nИтого: ${itemTotalPrice.toStringAsFixed(2)} BYN',
                                style: TextStyle(color: Colors.grey[700])),
                            trailing: _selectionMode
                                ? Text(
                                    '${itemTotalPrice.toStringAsFixed(2)} BYN',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        IconButton(
                                            iconSize: 22,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.orange[700]),
                                            onPressed: () => _decrementQuantity(
                                                item['product_id'] as int,
                                                quantity)),
                                        Text('$quantity',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        IconButton(
                                            iconSize: 22,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(Icons.add_circle_outline,
                                                color: theme.primaryColor),
                                            onPressed: () => _incrementQuantity(
                                                item['product_id'] as int,
                                                quantity)),
                                      ]),
                            onTap: _selectionMode
                                ? () => _toggleItemSelected(item['id'] as int)
                                : null,
                            onLongPress: !_selectionMode
                                ? () {
                                    _toggleSelectionMode();
                                    _toggleItemSelected(item['id'] as int);
                                  }
                                : null,
                            selected: isSelected,
                            selectedTileColor:
                                theme.primaryColor.withOpacity(0.08),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: cartItems.isNotEmpty && !_isLoading
          ? SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    final itemsForOrder =
                        _selectionMode && _selectedCartItemIds.isNotEmpty
                            ? cartItems
                                .where((item) => _selectedCartItemIds
                                    .contains(item['id'] as int))
                                .toList()
                            : cartItems;
                    if (itemsForOrder.isEmpty) {
                      _showErrorSnackbar(
                          'Выберите товары для оформления заказа.');
                      return;
                    }
                    // Используем _totalPrice, который уже учитывает режим выбора
                    print(
                        'Оформление заказа на сумму: ${_totalPrice.toStringAsFixed(2)} BYN');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Переход к оформлению заказа на ${_totalPrice.toStringAsFixed(2)} BYN (не реализовано)'),
                    ));
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(items: itemsForOrder, total: _totalPrice)));
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  child: Text(
                      'Оформить заказ (${_totalPrice.toStringAsFixed(2)} BYN)'),
                ),
              ),
            )
          : null,
    );
  }
}
