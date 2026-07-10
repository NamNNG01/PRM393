import 'package:flutter/material.dart';

class SettlementReportScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const SettlementReportScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isProfit = result["profit"] as bool;

    return Scaffold(
      appBar: AppBar(title: const Text("Báo cáo bồi hoàn")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "KẾT QUẢ BỒI HOÀN",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 25),

                _row("Loại", result["type"]),

                _row("Mã sản phẩm", result["productCode"]),

                const Divider(),

                _row(
                  result["type"] == "A"
                      ? "Đại lý đã giữ"
                      : "Đại lý đã giữ (điểm)",
                  result["retained"],
                ),

                if (result["type"] == "B")
                  _row("Giá bán / điểm", _money(result["ticketPrice"])),

                _row("Tỷ lệ bồi hoàn", _money(result["refundRate"])),

                if (result["type"] == "B") _row("Hệ số", result["multiplier"]),

                const Divider(),

                _row(
                  "Tổng tiền đại lí cầm (hoa hồng + tổng giữ lại)",
                  _money(result["totalRetained"]),
                ),

                _row("Tiền phải bồi hoàn", _money(result["refundMoney"])),

                const Divider(),

                _row("Sau bồi hoàn", _money(result["remaining"])),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isProfit
                        ? "🟢 Sau khi bồi hoàn đại lý vẫn còn lợi nhuận."
                        : "🔴 Sau khi bồi hoàn đại lý bị lỗ.",
                    style: TextStyle(
                      fontSize: 18,
                      color: isProfit
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _money(dynamic value) {
    return "${value.toString()} đ";
  }
}
