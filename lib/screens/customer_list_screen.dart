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
        "${date.year}";
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
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredCustomers();

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
                      "Khách Hàng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    Positioned(
                      left: 4,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
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
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Tìm tên hoặc số điện thoại...",
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
          ),

          // STATS HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.people_alt_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Tổng số khách: ",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${filtered.length}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // LIST VIEW
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 64, color: colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          "Không tìm thấy khách hàng nào",
                          style: TextStyle(color: colorScheme.outline, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      final lastDate = _lastPlayed(customer);
                      final ticketCount = _ticketCount(customer);

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
                        ),
                        color: colorScheme.surface,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerDetailScreen(customer: customer),
                              ),
                            ).then((_) {
                              setState(() {
                                customers = customerRepo.getAll().cast<Customer>();
                              });
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Text(
                                    customer.name.isEmpty
                                        ? "?"
                                        : customer.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            customer.phone,
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "$ticketCount vé",
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              lastDate == null
                                                  ? "Chưa giao dịch"
                                                  : "Lần cuối: ${_formatDate(lastDate)}",
                                              style: TextStyle(
                                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
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
