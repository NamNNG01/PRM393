import 'package:flutter/material.dart';
import '../services/order_parser.dart';
import '../repositories/order_repository.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

import '../models/ticket.dart';
import '../repositories/ticket_repository.dart';

import '../utils/date_util.dart';

class ImportOrderScreen extends StatefulWidget {
  const ImportOrderScreen({super.key});

  @override
  State<ImportOrderScreen> createState() => _ImportOrderScreenState();
}

class _ImportOrderScreenState extends State<ImportOrderScreen> {
  String selectedType = "A";
  bool showExample = false;

  final TextEditingController inputController = TextEditingController();
  final TextEditingController customerController = TextEditingController();

  final customerRepo = CustomerRepository();

  List<Customer> customers = [];

  Customer? selectedCustomer;

  bool showAddCustomer = false;

  final customerNameController = TextEditingController();
  final phoneController = TextEditingController();
  @override
  void initState() {
    super.initState();

    customers = customerRepo.getAll();
  }

  @override
  void dispose() {
    inputController.dispose();

    customerNameController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                      "Import Orders",
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
                          Icons.arrow_back,
                          color: colorScheme.onPrimary,
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Text(
              "Khách hàng",
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            if (customers.isNotEmpty && !showAddCustomer)
              DropdownButtonFormField<Customer>(
                initialValue: selectedCustomer,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Chọn khách hàng",
                ),
                items: customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text("${customer.name} - ${customer.phone}"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCustomer = value;
                  });
                },
              ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              icon: Icon(showAddCustomer ? Icons.close : Icons.person_add),
              label: Text(showAddCustomer ? "Hủy tạo khách" : "Thêm khách mới"),
              onPressed: () {
                setState(() {
                  showAddCustomer = !showAddCustomer;

                  if (showAddCustomer) {
                    /// chuyển sang chế độ tạo mới

                    selectedCustomer = null;

                    customerNameController.clear();
                    phoneController.clear();
                  } else {
                    /// quay lại dropdown

                    customerNameController.clear();
                    phoneController.clear();
                  }
                });
              },
            ),
            if (showAddCustomer || customers.isEmpty) ...[
              const SizedBox(height: 10),

              TextField(
                controller: customerNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Tên khách",
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Số điện thoại",
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text(
              "Loại đơn hàng",
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Chọn loại đơn hàng dạng segmented, dễ chạm trên mobile
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeOption(
                      label: "Type A",
                      subtitle: "Theo số tiền",
                      icon: Icons.payments_outlined,
                      selected: selectedType == "A",
                      color: Colors.indigo,
                      onTap: () => setState(() => selectedType = "A"),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _TypeOption(
                      label: "Type B",
                      subtitle: "Theo điểm",
                      icon: Icons.stars_outlined,
                      selected: selectedType == "B",
                      color: Colors.teal,
                      onTap: () => setState(() => selectedType = "B"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  "Danh sách đơn hàng",
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => showExample = !showExample),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          showExample ? "Ẩn ví dụ" : "Xem ví dụ",
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (showExample) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  "68 x5000000\n72 x3000000\n68 x1000000\n\nhoặc\n\n23 x1000\n79 x500\n23 x200",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: TextField(
                  controller: inputController,
                  minLines: 8,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText:
                        "Dán hoặc nhập danh sách đơn hàng, mỗi dòng một mã...",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final input = inputController.text.trim();

                  if (input.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Vui lòng nhập danh sách đơn hàng"),
                      ),
                    );
                    return;
                  }

                  final parsed = OrderParser.parseInput(input);
                  final totalValue = parsed.values.fold<num>(
                    0,
                    (a, b) => a + b,
                  );
                  final customerRepo = CustomerRepository();

                  Customer customer;

                  /// chế độ tạo khách mới
                  if (showAddCustomer || customers.isEmpty) {
                    final name = customerNameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Nhập tên khách hàng")),
                      );
                      return;
                    }

                    customer = await customerRepo.getOrCreate(
                      name: name,
                      phone: phoneController.text.trim(),
                    );
                  }
                  /// chọn từ dropdown
                  else {
                    if (selectedCustomer == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng chọn khách hàng"),
                        ),
                      );
                      return;
                    }

                    customer = selectedCustomer!;
                  }
                  final ticket = await TicketRepository().createTicket(
                    customerId: customer.id,
                    businessDate: DateUtil.today(),
                    type: selectedType,
                    totalValue: totalValue.toDouble(),
                  );

                  await OrderRepository().importOrders(
                    data: parsed,
                    type: selectedType,
                    customerId: customer.id,
                    ticketId: ticket.id,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },

                icon: const Icon(Icons.file_upload_outlined),
                label: const Text(
                  "IMPORT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.surface : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey[700],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? color.withValues(alpha: 0.8) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
