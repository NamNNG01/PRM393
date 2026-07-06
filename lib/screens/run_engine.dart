import 'package:flutter/material.dart';

import '../services/risk_engine.dart';
import '../repositories/order_repository.dart';
import '../models/order.dart';
import 'report.dart';

class RunEngineScreen extends StatelessWidget {
  const RunEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Run Engine"),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text("CALCULATE REPORT"),
          onPressed: () {
            final engine = RiskEngine();
            final repo = OrderRepository();

            final orders = repo.getAll();

            // tạm chia giả lập
            final Map<Order, double> dataA = {};
            final Map<Order, int> dataB = {};

            for (var o in orders) {
              if (o.type == "A") {
                dataA[o] = o.amount;
              } else {
                dataB[o] = o.unit;
              }
            }

            final resultA = engine.processTypeA(dataA);
            final resultB = engine.processTypeB(dataB);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportScreen(
                  resultA: resultA,
                  resultB: resultB,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}