import 'package:flutter/material.dart';

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
  void dispose() {
    multiplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orders = repo.getAll();

    final codes = orders
        .where((e) => e.type == type)
        .map((e) => e.productCode)
        .toSet()
        .toList();

    if (codes.isNotEmpty && selectedCode == null) {
      selectedCode = codes.first;
    }

    final bool canCalculate = codes.isNotEmpty && selectedCode != null;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight + 12,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      "Tính bồi hoàn",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    Positioned(
                      left: 4,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calculate_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Thông tin tính bồi hoàn",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: InputDecoration(
                        labelText: "Loại vé",
                        prefixIcon: Icon(Icons.confirmation_number_outlined, color: colorScheme.primary),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "A", child: Text("Vé Loại A")),
                        DropdownMenuItem(value: "B", child: Text("Vé Loại B")),
                      ],
                      onChanged: (v) {
                        setState(() {
                          type = v!;
                          selectedCode = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (codes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Không tìm thấy mã sản phẩm nào cho Loại vé $type. Vui lòng thêm đơn hàng trước.",
                                style: const TextStyle(color: Colors.orange, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: selectedCode,
                        decoration: InputDecoration(
                          labelText: "Mã sản phẩm",
                          prefixIcon: Icon(Icons.qr_code_scanner_rounded, color: colorScheme.primary),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                          ),
                        ),
                        items: codes
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedCode = v;
                          });
                        },
                      ),
                    ],
                    if (type == "B") ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: multiplierController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Hệ số",
                          prefixIcon: const Icon(Icons.star_border_outlined, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: canCalculate
                  ? LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    )
                  : null,
              color: canCalculate ? null : Colors.grey[300],
              boxShadow: canCalculate
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: canCalculate
                    ? () {
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
                            multiplier: int.tryParse(multiplierController.text) ?? 1,
                            ticketPrice: config.ticketPriceB,
                          );
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettlementReportScreen(result: result),
                          ),
                        );
                      }
                    : null,
                child: SizedBox(
                  height: 54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        color: canCalculate ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "TÍNH BỒI HOÀN",
                        style: TextStyle(
                          color: canCalculate ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
