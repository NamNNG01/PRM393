import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../repositories/order_repository.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

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
  // Đơn vị tiền: 1.0 = nghìn đồng, 0.001 = đồng
  double _amountUnit = 1.0;

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

  Map<String, double> _parseAndValidateInput(String input) {
    final Map<String, double> result = {};
    final lines = input.split('\n');

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;

      final lineNumber = i + 1;

      final clean = line
          .replaceAll(',', ' ')
          .replaceAll(':', ' ')
          .replaceAll('*', ' ')
          .replaceAll('-', ' ')
          .replaceAll('x', ' ')
          .replaceAll('X', ' ')
          .trim();

      final parts = clean.split(RegExp(r'\s+'));

      if (parts.length < 2) {
        throw FormatException(
          "Dòng $lineNumber: Sai định dạng '$line'. Định dạng đúng ví dụ: 90 x 50000",
        );
      }

      final codeStr = parts[0];
      final codeInt = int.tryParse(codeStr);
      if (codeInt == null || codeInt < 0 || codeInt > 99) {
        throw FormatException(
          "Dòng $lineNumber: Mã '$codeStr' không hợp lệ. Chỉ chấp nhận mã từ 00 đến 99.",
        );
      }

      final valueStr = parts[1];
      final value = double.tryParse(valueStr);
      if (value == null || value <= 0) {
        throw FormatException(
          "Dòng $lineNumber: Số tiền '$valueStr' không hợp lệ. Phải là số dương.",
        );
      }

      if (selectedType == "A" && _amountUnit == 0.001 && value < 1000) {
        throw FormatException(
          "Dòng $lineNumber: Số tiền '$valueStr' không hợp lệ. Khi chọn đơn vị Đồng, số tiền tối thiểu phải là 1.000đ.",
        );
      }

      final normalizedCode = codeInt.toString().padLeft(2, '0');
      result[normalizedCode] = (result[normalizedCode] ?? 0) + value;
    }

    return result;
  }

  Widget _buildDynamicExampleBox(ColorScheme colorScheme) {
    String title = "";
    String content = "";

    if (selectedType == "A") {
      if (_amountUnit == 1.0) {
        title = "Định dạng nhập Loại A: [mã] x [số tiền] (Đơn vị: Nghìn đồng)";
        content =
            "• Mã phải từ 00 đến 99.\n"
            "• Quy ước nhập tiền:\n"
            "  - 10 = 10.000 VNĐ\n"
            "  - 100 = 100.000 VNĐ\n"
            "  - 1000 = 1.000.000 VNĐ\n\n"
            "Ví dụ hợp lệ:\n"
            "90 x 10 (Mã 90, số tiền 10.000 VNĐ)\n"
            "23 x 100 (Mã 23, số tiền 100.000 VNĐ)\n\n"
            "Ví dụ không hợp lệ:\n"
            "100 x 50 (Mã > 99)\n"
            "abc x 10 (Mã không phải số)";
      } else {
        title = "Định dạng nhập Loại A: [mã] x [số tiền] (Đơn vị: Đồng)";
        content =
            "• Mã phải từ 00 đến 99.\n"
            "• Quy ước nhập tiền:\n"
            "  - 10000 = 10.000 VNĐ\n"
            "  - 100000 = 100.000 VNĐ\n"
            "  - Tối thiểu phải từ 1.000 VNĐ trở lên.\n\n"
            "Ví dụ hợp lệ:\n"
            "90 x 10000 (Mã 90, số tiền 10.000 VNĐ)\n"
            "23 x 100000 (Mã 23, số tiền 100.000 VNĐ)\n\n"
            "Ví dụ không hợp lệ:\n"
            "90 x 500 (Số tiền dưới 1.000 VNĐ)\n"
            "100 x 10000 (Mã > 99)";
      }
    } else {
      title = "Định dạng nhập Loại B: [mã] x [điểm] (Đơn vị: Điểm)";
      content =
          "• Mã phải từ 00 đến 99.\n"
          "• Nhập số điểm trực tiếp:\n"
          "  - 10 = 10 điểm\n"
          "  - 100 = 100 điểm\n\n"
          "Ví dụ hợp lệ:\n"
          "90 x 10 (Mã 90, 10 điểm)\n"
          "23 x 100 (Mã 23, 100 điểm)\n\n"
          "Ví dụ không hợp lệ:\n"
          "100 x 5 (Mã > 99)\n"
          "90 x -5 (Điểm không hợp lệ)";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
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
                      "Nhập mã",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD 1: KHÁCH HÀNG
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_pin_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Thông tin khách hàng",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (customers.isNotEmpty && !showAddCustomer) ...[
                      DropdownButtonFormField<Customer>(
                        initialValue: selectedCustomer,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.assignment_ind_outlined,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          labelText: "Chọn khách hàng có sẵn",
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
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
                    ],
                    if (showAddCustomer || customers.isEmpty) ...[
                      TextField(
                        controller: customerNameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          labelText: "Tên khách hàng mới",
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          labelText: "Số điện thoại",
                          helperText: "Nhập đúng 10 chữ số",
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (customers.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              showAddCustomer = !showAddCustomer;

                              if (!showAddCustomer) {
                                customerNameController.clear();
                                phoneController.clear();
                              }
                            });
                          },
                          icon: Icon(
                            showAddCustomer ? Icons.close : Icons.person_add,
                            size: 18,
                          ),
                          label: Text(
                            showAddCustomer
                                ? "Hủy thêm khách"
                                : "Thêm khách mới",
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CARD 2: CÀI ĐẶT & NỘI DUNG mã
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Cài đặt & Nội dung mã",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loại mã",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                              label: "Loại A",
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
                              label: "Loại B",
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
                    if (selectedType == "A") ...[
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            color: colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Đơn vị tiền:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<double>(
                        initialValue: _amountUnit,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1.0,
                            child: Text(
                              'Nghìn đồng (×1.000)',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 0.001,
                            child: Text(
                              'Đồng (×1)',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _amountUnit = v ?? 1.0;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          "Danh sách mã",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              setState(() => showExample = !showExample),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  showExample ? "Ẩn ví dụ" : "Xem ví dụ",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
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
                      _buildDynamicExampleBox(colorScheme),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: inputController,
                      minLines: 6,
                      maxLines: 12,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: selectedType == "A"
                            ? (_amountUnit == 1.0
                                  ? "Dán hoặc nhập mã Loại A (Nghìn đồng)...\nVí dụ:\n90 x 10\n05 x 100"
                                  : "Dán hoặc nhập mã Loại A (Đồng)...\nVí dụ:\n90 x 10000\n05 x 100000")
                            : "Dán hoặc nhập mã Loại B (Điểm)...\nVí dụ:\n90 x 10\n05 x 100",
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        helperText: selectedType == "A"
                            ? (_amountUnit == 1.0
                                  ? "Lưu ý nhập tiền: 10 = 10.000 VNĐ, 100 = 100.000 VNĐ. Phân cách: x, *, -, dấu cách hoặc :"
                                  : "Lưu ý nhập tiền: Nhập đúng số tiền đồng (tối thiểu 1000). Ví dụ: 10000 = 10.000 VNĐ.")
                            : "Lưu ý nhập điểm: Nhập trực tiếp số điểm. Ví dụ: 10 = 10 điểm.",
                        helperMaxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // NÚT NHẬP
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final input = inputController.text.trim();

                  if (input.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Vui lòng nhập danh sách mã"),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Map<String, double> parsed;
                  try {
                    parsed = _parseAndValidateInput(input);
                  } on FormatException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.message)),
                          ],
                        ),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Áp dụng đơn vị tiền vào tất cả giá trị (chỉ áp dụng cho loại A)
                  final multiplied = parsed.map(
                    (k, v) =>
                        MapEntry(k, selectedType == "A" ? v * _amountUnit : v),
                  );

                  final totalValue = multiplied.values.fold<num>(
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
                        const SnackBar(
                          content: Text("Nhập tên khách hàng"),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final phone = phoneController.text.trim();
                    if (phone.isNotEmpty &&
                        !RegExp(r'^\d{10}$').hasMatch(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Số điện thoại phải là số và gồm đúng 10 chữ số",
                          ),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                        ),
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
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
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
                    data: multiplied,
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
                  "NHẬP",
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
