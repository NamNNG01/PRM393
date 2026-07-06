import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../hive/hive_boxes.dart';
import '../models/order.dart';
import 'import_order.dart';
import 'run_engine.dart';
import 'settings.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),

        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RunEngineScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: Hive.box<Order>(HiveBoxes.orderBox).listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text("No Orders", style: TextStyle(fontSize: 20)),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final order = box.getAt(index)!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                child: ListTile(
                  leading: CircleAvatar(child: Text(order.type)),

                  title: Text("Product ${order.productCode}"),

                  subtitle: order.type == "A"
                      ? Text("Amount : ${order.amount.toStringAsFixed(0)}")
                      : Text("Unit : ${order.unit}"),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await box.deleteAt(index);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImportOrderScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Import"),
      ),
    );
  }
}
