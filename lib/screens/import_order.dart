import 'package:flutter/material.dart';
import '../services/order_parser.dart';
import '../repositories/order_repository.dart';

class ImportOrderScreen extends StatefulWidget {
  const ImportOrderScreen({super.key});

  @override
  State<ImportOrderScreen> createState() => _ImportOrderScreenState();
}

class _ImportOrderScreenState extends State<ImportOrderScreen> {
  String selectedType = "A";

  final TextEditingController inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Import Orders")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Order Type",
              ),

              items: const [
                DropdownMenuItem(value: "A", child: Text("Type A")),

                DropdownMenuItem(value: "B", child: Text("Type B")),
              ],

              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: TextField(
                controller: inputController,

                expands: true,

                maxLines: null,

                minLines: null,

                textAlignVertical: TextAlignVertical.top,

                decoration: const InputDecoration(
                  border: OutlineInputBorder(),

                  hintText: """Ví dụ:

68 x5000000
72 x3000000
68 x1000000

hoặc

23 x1000
79 x500
23 x200""",
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed: () async {
                  final input = inputController.text.trim();

                  if (input.isEmpty) return;

                  final parsed = OrderParser.parseInput(input);

                  await OrderRepository().importOrders(parsed, selectedType);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },

                child: const Text("IMPORT", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
