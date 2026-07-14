import 'dart:io';

import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../models/winning_ticket.dart';
import '../widgets/proof_image_view.dart';

import '../repositories/order_repository.dart';
import '../repositories/winning_repository.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final orderRepo = OrderRepository();
  final winningRepo = WinningRepository();

  final searchController = TextEditingController();

  String selectedDate = "ALL";

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${(date.year % 100).toString().padLeft(2, '0')}";
  }

  List<Order> _orders() {
    final orders = orderRepo.getByCustomer(widget.customer.id).cast<Order>();

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders();

    final dates = orders.map((e) => e.businessDate).toSet().toList();

    final filtered = orders.where((o) {
      final keyword = searchController.text.trim().toLowerCase();

      final matchCode = keyword.isEmpty
          ? true
          : o.productCode.toLowerCase().contains(keyword);

      final matchDate = selectedDate == "ALL"
          ? true
          : o.businessDate == selectedDate;

      return matchCode && matchDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.customer.name)),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.phone),
                      const SizedBox(width: 8),
                      Text(widget.customer.phone),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.receipt_long),
                      const SizedBox(width: 8),
                      Text("Tổng vé: ${orders.length}"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Tìm mã số",
              ),
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              initialValue: "ALL",
              decoration: const InputDecoration(labelText: "Lọc theo ngày"),
              items: [
                const DropdownMenuItem(value: "ALL", child: Text("Tất cả")),

                ...dates.map((e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (v) {
                setState(() {
                  selectedDate = v ?? "ALL";
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Không có dữ liệu"))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final order = filtered[index];

                      final winning = winningRepo.findByTicket(order.ticketId);

                      final isWinner = winning != null;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order.productCode,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const Spacer(),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: order.type == "A"
                                          ? Colors.indigo
                                          : Colors.teal,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      order.type,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text("Ngày: ${order.businessDate}"),

                              Text(
                                order.type == "A"
                                    ? "Giá trị: ${order.amount * 1000}đ"
                                    : "Điểm: ${order.unit} điểm",
                              ),

                              const Divider(),

                              if (!isWinner) const Text("❌ Chưa trúng"),

                              if (isWinner)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "🎉 Vé trúng",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      winning.paid
                                          ? "✅ Đã thanh toán"
                                          : "⏳ Chưa thanh toán",
                                    ),

                                    if (winning.paidAt != null)
                                      Text(
                                        "Cập nhật: ${_formatDate(winning.paidAt!)}",
                                      ),

                                    if (winning.note != null &&
                                        winning.note!.isNotEmpty)
                                      Text("Ghi chú: ${winning.note}"),

                                    if (winning.proofImageBytes != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.memory(
                                            winning.proofImageBytes!,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
