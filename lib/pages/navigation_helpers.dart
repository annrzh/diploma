import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'authPage.dart';
import 'profilePage.dart';

Future<void> openProfilePage(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');

  if (userId == null) {
    // Если нет userId — отправляем на страницу авторизации
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const authPage()),
    );
    return;
  }

  // Иначе открываем профиль с userId
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => profilePage(userId: userId),
    ),
  );
}
