import 'package:flutter/material.dart';

import '../screens/add_product/add_product_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/inventory/inventory_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => const HomeScreen(),
    '/inventory': (context) => const InventoryScreen(),
    '/add-product': (context) => const AddProductScreen(),
  };
}
