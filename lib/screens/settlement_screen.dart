import 'package:flutter/material.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../services/config_service.dart';
import '../services/settlement_service.dart';
import 'settlement_report.dart';

class SettlementScreen extends StatefulWidget {
  final Map<String, dynamic> resultA;
  final Map<String, dynamic> resultB;

  const SettlementScreen({
    super.key,
    required this.resultA,
    required this.resultB,
  });

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  String type = "A";

  String? selectedCode;

  final multiplierController = TextEditingController(text: "1");

  final repo = OrderRepository();

  @override
  Widget build(BuildContext context) {
    final orders = repo.getAll();

    final codes = orders
        .where((e) => e.type == type)
        .map((e) => e.productCode)
        .toSet()
        .toList();

    if (codes.isNotEmpty && selectedCode == null) {
      selectedCode = codes.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Bồi hoàn")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: "Loại vé"),
              items: const [
                DropdownMenuItem(value: "A", child: Text("Type A")),
                DropdownMenuItem(value: "B", child: Text("Type B")),
              ],
              onChanged: (v) {
                setState(() {
                  type = v!;
                  selectedCode = null;
                });
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedCode,
              decoration: const InputDecoration(labelText: "Mã sản phẩm"),
              items: codes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedCode = v;
                });
              },
            ),

            const SizedBox(height: 20),

            if (type == "B")
              TextField(
                controller: multiplierController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Hệ số"),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("TÍNH BỒI HOÀN"),
                onPressed: () {
                  final config = ConfigService().getConfig();

                  final settlement = SettlementService();

                  late Map<String, dynamic> result;

                  if (type == "A") {
                    result = settlement.calculateTypeA(
                      report: widget.resultA,
                      productCode: selectedCode!,
                      refundRate: config.refundRateA,
                    );
                  } else {
                    result = settlement.calculateTypeB(
                      report: widget.resultB,
                      productCode: selectedCode!,
                      refundRate: config.refundRateB,
                      multiplier: int.parse(multiplierController.text),
                      ticketPrice: config.ticketPriceB,
                    );
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettlementReportScreen(result: result),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
