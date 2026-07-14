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
    if (keyword.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(keyword) ||
          c.phone.toLowerCase().contains(keyword);
    }).toList();
  }

  DateTime? _lastPlayed(Customer customer) {
    final orders = orderRepo.getByCustomer(customer.id).cast<Order>();
    if (orders.isEmpty) return null;
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders.first.createdAt;
  }

  int _ticketCount(Customer customer) {
    return orderRepo.getByCustomer(customer.id).length;
  }

  void _reloadCustomers() {
    setState(() {
      customers = customerRepo.getAll().cast<Customer>();
    });
  }

  /// Mở dialog thêm mới hoặc sửa khách hàng
  Future<void> _openCustomerDialog({Customer? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = existing != null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isEdit ? 'Sửa khách hàng' : 'Thêm khách hàng',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Tên khách hàng *',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.error,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập tên khách hàng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // SĐT
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.error,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final phone = v.trim();
                      final found = customerRepo.findByPhone(phone);
                      if (found != null && found.id != existing?.id) {
                        return 'Số điện thoại này đã tồn tại';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Ghi chú
                TextFormField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon: Icon(
                      Icons.notes_outlined,
                      color: colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            icon: Icon(
              isEdit ? Icons.save_rounded : Icons.add_rounded,
              size: 18,
            ),
            label: Text(isEdit ? 'Lưu' : 'Thêm'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              if (isEdit) {
                existing.name = nameCtrl.text.trim();
                existing.phone = phoneCtrl.text.trim();
                existing.note = noteCtrl.text.trim();
                await customerRepo.update(existing);
              } else {
                await customerRepo.add(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  note: noteCtrl.text.trim(),
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
              _reloadCustomers();
            },
          ),
        ],
      ),
    );
  }

  /// Dialog xác nhận xóa
  Future<void> _deleteCustomer(Customer customer) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text(
              'Xóa khách hàng',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa khách hàng "${customer.name}" không?\n'
          'Dữ liệu mã liên quan sẽ vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await customerRepo.delete(customer);
      _reloadCustomers();
    }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomerDialog(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Thêm khách',
          style: TextStyle(fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
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

          // LIST
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Không tìm thấy khách hàng nào",
                          style: TextStyle(
                            color: colorScheme.outline,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _openCustomerDialog(),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Thêm khách hàng mới'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
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
                          side: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
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
                            ).then((_) => _reloadCustomers());
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            child: Row(
                              children: [
                                // Avatar
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
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 13,
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            customer.phone.isEmpty
                                                ? 'Chưa có SĐT'
                                                : customer.phone,
                                            style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (customer.note.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.notes_outlined,
                                              size: 13,
                                              color: colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.7),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                customer.note,
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "$ticketCount Mã",
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
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.8),
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
                                // Edit / Delete
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      tooltip: 'Sửa',
                                      onPressed: () => _openCustomerDialog(
                                        existing: customer,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: colorScheme.error,
                                      ),
                                      tooltip: 'Xóa',
                                      onPressed: () =>
                                          _deleteCustomer(customer),
                                    ),
                                  ],
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
