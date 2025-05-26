import 'package:flutter/material.dart';

class cartsPage extends StatefulWidget {
  const cartsPage({super.key});

  @override
  _CartsPageState createState() => _CartsPageState();
}

class _CartsPageState extends State<cartsPage> {
  List<Map<String, dynamic>> cartItems = [
    {'id': 1, 'name': 'Товар 1', 'price': 1500.0, 'amount': 2},
    {'id': 2, 'name': 'Товар 2', 'price': 700.0, 'amount': 1},
    {'id': 3, 'name': 'Товар 3', 'price': 1200.0, 'amount': 3},
  ];

  bool selectionMode = false;
  Set<int> selectedItems = {};

  double get totalPrice {
    final items = selectionMode && selectedItems.isNotEmpty
        ? cartItems.where((item) => selectedItems.contains(item['id']))
        : cartItems;
    return items.fold(0.0, (sum, item) => sum + item['price'] * item['amount']);
  }

  void toggleSelectionMode() {
    setState(() {
      selectionMode = !selectionMode;
      if (!selectionMode) selectedItems.clear();
    });
  }

  void toggleItemSelected(int id) {
    setState(() {
      if (selectedItems.contains(id)) {
        selectedItems.remove(id);
      } else {
        selectedItems.add(id);
      }
    });
  }

  void incrementAmount(int id) {
    setState(() {
      final item = cartItems.firstWhere((element) => element['id'] == id);
      item['amount'] += 1;
    });
  }

  void decrementAmount(int id) {
    setState(() {
      final item = cartItems.firstWhere((element) => element['id'] == id);
      if (item['amount'] > 1) item['amount'] -= 1;
    });
  }

  void removeSelectedItems() async {
    final count = selectedItems.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Удалить $count товар(ов)?'),
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
      setState(() {
        cartItems.removeWhere((item) => selectedItems.contains(item['id']));
        selectedItems.clear();
        selectionMode = false;
      });
    }
  }

  int _currentIndex = 2; // Корзина — третий пункт меню

  void _onTap(int index) {
    if (index == _currentIndex) return; // Уже здесь

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/homePage');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/searchPage');
        break;
      case 2:
        // Корзина — здесь
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
        title: const Text('Корзина'),
        backgroundColor: Colors.green,
        leading: selectionMode
            ? IconButton(
                icon: const Icon(Icons.delete),
                onPressed: selectedItems.isEmpty ? null : removeSelectedItems,
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(selectionMode ? Icons.close : Icons.checklist,
                    color: Colors.green),
                onPressed: toggleSelectionMode,
                tooltip: selectionMode ? 'Отменить выбор' : 'Выбрать товары',
              ),
            ),
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Корзина пуста'))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final bool isSelected = selectedItems.contains(item['id']);
                return ListTile(
                  leading: selectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => toggleItemSelected(item['id']),
                        )
                      : null,
                  title: Text(item['name']),
                  subtitle: Text(
                      'Цена: ${item['price']} × ${item['amount']} = ${(item['price'] * item['amount']).toStringAsFixed(2)}'),
                  trailing: selectionMode
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => decrementAmount(item['id']),
                            ),
                            Text('${item['amount']}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => incrementAmount(item['id']),
                            ),
                          ],
                        ),
                  onTap: selectionMode
                      ? () => toggleItemSelected(item['id'])
                      : () {
                          // Можно добавить детали товара
                        },
                );
              },
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty
                  ? null
                  : () {
                      final itemsForOrder = selectionMode &&
                              selectedItems.isNotEmpty
                          ? cartItems
                              .where(
                                  (item) => selectedItems.contains(item['id']))
                              .toList()
                          : cartItems;

                      final total = itemsForOrder.fold<double>(0,
                          (sum, item) => sum + item['price'] * item['amount']);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Оформление заказа на сумму: ${total.toStringAsFixed(2)} ₽'),
                      ));
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Оформить заказ (₽ ${totalPrice.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          BottomNavigationBar(
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
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Профиль'),
            ],
          ),
        ],
      ),
    );
  }
}
