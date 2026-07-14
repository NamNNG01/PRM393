import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/order.dart';

import '../repositories/customer_repository.dart';
import '../repositories/order_repository.dart';

import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final customerRepo = CustomerRepository();
  final orderRepo = OrderRepository();

  final searchController = TextEditingController();

  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();

    customers = customerRepo.getAll().cast<Customer>();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${(date.year % 100).toString().padLeft(2, '0')}";
  }

  List<Customer> _filteredCustomers() {
    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      return customer.name.toLowerCase().contains(keyword) ||
          customer.phone.toLowerCase().contains(keyword);
    }).toList();
  }

  DateTime? _lastPlayed(Customer customer) {
    final orders = orderRepo.getByCustomer(customer.id).cast<Order>();

    if (orders.isEmpty) {
      return null;
    }

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders.first.createdAt;
  }

  int _ticketCount(Customer customer) {
    return orderRepo.getByCustomer(customer.id).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCustomers();

    return Scaffold(
      appBar: AppBar(title: const Text("Khách hàng")),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Tìm tên hoặc số điện thoại",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Tổng khách: ${filtered.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Không tìm thấy khách hàng"))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final customer = filtered[index];

                      final lastDate = _lastPlayed(customer);

                      final ticketCount = _ticketCount(customer);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              customer.name.isEmpty
                                  ? "?"
                                  : customer.name[0].toUpperCase(),
                            ),
                          ),

                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),

                              Text(customer.phone),

                              const SizedBox(height: 4),

                              Text("Số vé: $ticketCount"),

                              Text(
                                lastDate == null
                                    ? "Chưa có giao dịch"
                                    : "Lần gần nhất: ${_formatDate(lastDate)}",
                              ),
                            ],
                          ),

                          trailing: const Icon(Icons.chevron_right),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerDetailScreen(customer: customer),
                              ),
                            );
                          },
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
