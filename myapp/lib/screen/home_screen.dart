import 'package:flutter/material.dart';
import 'customer/customer_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, String role = 'customer'});

  @override
  Widget build(BuildContext context) => const CustomerHomeScreen();
}
