import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.pushNamed(context, '/earnings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Delivery partner tasks - To be implemented'),
      ),
    );
  }
}
