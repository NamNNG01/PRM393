import 'package:flutter/material.dart';
import 'order.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Ticket Manager"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrderScreen(),
              ),
            );
          },
          child: const Text("Manage Orders"),
        ),
      ),
    );
  }
}