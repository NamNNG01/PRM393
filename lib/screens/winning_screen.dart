import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order.dart';
import '../models/winning_ticket.dart';
import 'package:hive/hive.dart';
import '../models/configuration.dart';
import '../hive/hive_boxes.dart';
import 'package:intl/intl.dart';

import '../repositories/order_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/winning_repository.dart';
import '../repositories/winning_result_repository.dart';
import '../models/winning_result.dart';
import '../utils/date_util.dart';

class WinningScreen extends StatefulWidget {
  const WinningScreen({super.key});

  @override
  State<WinningScreen> createState() => _WinningScreenState();
}

String money(num value) {
  return NumberFormat("#,###", "vi_VN").format(value);
}

class WinnerGroup {
  final String customerId;
  final String customerName;
  final String phone;

  final List<WinningTicket> tickets;

  WinnerGroup({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.tickets,
  });

  double get totalPayout => tickets.fold(0, (s, e) => s + e.payoutAmount);

  double get totalValue => tickets.fold(0, (s, e) => s + e.orderValue);

  int get totalA => tickets.where((e) => e.ticketType == "A").length;

  int get totalB => tickets.where((e) => e.ticketType == "B").length;

  bool get isPaid => tickets.every((e) => e.paid);
}

class WinningBItem {
  String number;
  double multiplier;

  WinningBItem({required this.number, required this.multiplier});
}

class _WinningScreenState extends State<WinningScreen> {
  final winningController = TextEditingController();

  final orderRepo = OrderRepository();
  final customerRepo = CustomerRepository();
  final ticketRepo = TicketRepository();
  final winningRepo = WinningRepository();
  final winningResultRepo = WinningResultRepository();
  late Configuration config;

  String selectedType = "A";
  List<WinningTicket> winners = [];

  List<WinningBItem> winningBItems = [WinningBItem(number: "", multiplier: 1)];

  /// ==== FILTER (chỉ ảnh hưởng hiển thị, không đụng dữ liệu) ====
  final searchController = TextEditingController();
  String keyword = "";
  String statusFilter = "all"; // all | paid | unpaid

  List<WinnerGroup> buildGroups() {
    final map = <String, List<WinningTicket>>{};

    for (final t in winners) {
      map.putIfAbsent(t.customerId, () => []);
      map[t.customerId]!.add(t);
    }

    return map.entries.map((e) {
      final customer = customerRepo.getById(e.key);

      return WinnerGroup(
        customerId: e.key,
        customerName: customer?.name ?? "",
        phone: customer?.phone ?? "",
        tickets: e.value,
      );
    }).toList();
  }

  void loadWinningB() {
    final today = DateUtil.today();

    final result = winningResultRepo.getResult(today, "B");

    if (result == null) return;

    final values = result.winningNumbers
        .split(",")
        .where((e) => e.trim().isNotEmpty);

    winningBItems = values.map((e) {
      final parts = e.split(":");

      return WinningBItem(
        number: parts[0],
        multiplier: parts.length > 1 ? double.tryParse(parts[1]) ?? 1 : 1,
      );
    }).toList();
  }

  Future<void> findWinner() async {
    bool isValidNumber(String value) {
      return RegExp(r'^\d{2}$').hasMatch(value);
    }

    final input = winningController.text.trim();

    if (selectedType == "A" && input.isEmpty) {
      return;
    }
    final today = DateUtil.today();

    final orders = orderRepo.getByBusinessDate(today);

    if (selectedType == "A") {
      if (winningResultRepo.exists(today, "A")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Loại A đã được xác nhận hôm nay")),
        );

        return;
      }

      final number = input;

      if (!isValidNumber(number)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mã sinh lời phải từ 00 đến 99")),
        );
        return;
      }

      await winningResultRepo.saveOrUpdate(
        businessDate: today,
        ticketType: "A",
        winningNumbers: number,
      );

      final matched = orders.where(
        (o) => o.type == "A" && o.productCode == number,
      );

      for (final Order order in matched) {
        final payout = order.amount * config.refundRateA * 1000;

        await winningRepo.add(
          WinningTicket(
            ticketId: order.ticketId,
            customerId: order.customerId,
            businessDate: today,
            winningNumber: number,
            ticketType: "A",
            orderValue: order.amount * 1000,
            payoutAmount: payout,
          ),
        );
      }
    } else {
      final items = winningBItems
          .where((e) => e.number.trim().isNotEmpty)
          .toList();

      if (items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Phải nhập ít nhất 1 mã")));
        return;
      }

      /// validate
      for (final item in items) {
        if (!isValidNumber(item.number)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Số không hợp lệ: ${item.number}")),
          );
          return;
        }

        if (item.multiplier <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hệ số không hợp lệ cho mã ${item.number}")),
          );
          return;
        }
      }

      /// lưu kết quả
      await winningResultRepo.saveOrUpdate(
        businessDate: today,
        ticketType: "B",
        winningNumbers: items
            .map((e) => "${e.number}:${e.multiplier}")
            .join(","),
      );

      for (final item in items) {
        final existed = winningRepo
            .getByDate(today)
            .any((e) => e.ticketType == "B" && e.winningNumber == item.number);

        if (existed) continue;

        final matched = orders.where(
          (o) => o.type == "B" && o.productCode == item.number,
        );

        for (final Order order in matched) {
          final payout = order.unit * config.refundRateB * item.multiplier;

          final orderValue = order.unit * config.ticketPriceB;

          await winningRepo.add(
            WinningTicket(
              ticketId: order.ticketId,
              customerId: order.customerId,
              businessDate: today,
              winningNumber: item.number,
              ticketType: "B",
              multiplier: item.multiplier,
              orderValue: orderValue,
              payoutAmount: payout,
            ),
          );
        }
      }
    }

    setState(() {
      winners = winningRepo.getByDate(today);
    });
  }

  @override
  void initState() {
    super.initState();

    winners = winningRepo.getByDate(DateUtil.today());
    config = Hive.box<Configuration>(HiveBoxes.configBox).values.first;
    final today = DateUtil.today();

    final result = winningResultRepo.getResult(today, "A");

    if (result != null) {
      winningController.text = result.winningNumbers;
    }
    loadWinningB();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allGroups = buildGroups();
    final kw = keyword.toLowerCase().trim();

    final groups = allGroups.where((g) {
      final matchKw =
          kw.isEmpty ||
          g.customerName.toLowerCase().contains(kw) ||
          g.phone.toLowerCase().contains(kw);

      final matchStatus =
          statusFilter == "all" ||
          (statusFilter == "paid" && g.isPaid) ||
          (statusFilter == "unpaid" && !g.isPaid);

      return matchKw && matchStatus;
    }).toList();

    final isLocked =
        winningResultRepo.getResult(DateUtil.today(), selectedType) != null;

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
                      "Xác nhận Mã sinh lời",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Nhập mã sinh lời hôm nay",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// Chọn loại Mã dạng segmented
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TicketTypeOption(
                            label: "Loại A",
                            selected: selectedType == "A",
                            color: Colors.indigo,
                            onTap: () {
                              setState(() {
                                selectedType = "A";
                                final result = winningResultRepo.getResult(
                                  DateUtil.today(),
                                  "A",
                                );
                                winningController.text =
                                    result?.winningNumbers ?? "";
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _TicketTypeOption(
                            label: "Loại B",
                            selected: selectedType == "B",
                            color: Colors.teal,
                            onTap: () {
                              setState(() {
                                selectedType = "B";
                                final result = winningResultRepo.getResult(
                                  DateUtil.today(),
                                  "B",
                                );
                                winningController.text =
                                    result?.winningNumbers ?? "";
                                loadWinningB();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  selectedType == "A"
                      ? TextField(
                          controller: winningController,
                          enabled: !isLocked,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: selectedType == "A"
                                ? "Mã sinh lời (00-99)"
                                : "Nhập nhiều số, cách nhau dấu phẩy: 12,34,56",
                            prefixIcon: Icon(
                              Icons.confirmation_number_outlined,
                              color: selectedType == "A"
                                  ? Colors.indigo
                                  : Colors.teal,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: isLocked
                                ? Colors.grey[100]
                                : colorScheme.surfaceContainerLowest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...winningBItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              return Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      enabled: !isLocked,

                                      initialValue: item.number,
                                      decoration: const InputDecoration(
                                        labelText: "Mã",
                                      ),
                                      onChanged: (v) {
                                        item.number = v;
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: TextFormField(
                                      enabled: !isLocked,

                                      initialValue: item.multiplier.toString(),
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: "Hệ số",
                                      ),
                                      onChanged: (v) {
                                        item.multiplier =
                                            double.tryParse(v) ?? 1;
                                      },
                                    ),
                                  ),
                                  if (!isLocked)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          winningBItems.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                ],
                              );
                            }),
                            if (!isLocked)
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    winningBItems.add(
                                      WinningBItem(number: "", multiplier: 1),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Thêm mã"),
                              ),
                          ],
                        ),
                  if (isLocked) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Loại $selectedType đã được xác nhận hôm nay",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: isLocked ? null : findWinner,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        "Xác nhận",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ==== KHU VỰC FILTER DANH SÁCH NGƯỜI sinh lời ====
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (v) => setState(() => keyword = v),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: "Tìm theo tên khách hoặc SĐT...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: keyword.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              setState(() => keyword = "");
                            },
                          ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusFilterChip(
                        label: "Tất cả",
                        selected: statusFilter == "all",
                        color: colorScheme.primary,
                        onTap: () => setState(() => statusFilter = "all"),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: "Chưa thanh toán",
                        selected: statusFilter == "unpaid",
                        color: Colors.orange,
                        onTap: () => setState(() => statusFilter = "unpaid"),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: "Đã thanh toán",
                        selected: statusFilter == "paid",
                        color: Colors.green,
                        onTap: () => setState(() => statusFilter = "paid"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          allGroups.isEmpty
                              ? "Chưa có Mã sinh lời"
                              : "Không tìm thấy kết quả phù hợp",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: groups.length,
                    itemBuilder: (_, index) {
                      return _WinnerGroupCard(group: groups[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketTypeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TicketTypeOption({
    required this.label,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
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
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? color : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : color,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _WinnerGroupCard extends StatefulWidget {
  final WinnerGroup group;

  const _WinnerGroupCard({super.key, required this.group});

  @override
  State<_WinnerGroupCard> createState() => _WinnerGroupCardState();
}

class _WinnerGroupCardState extends State<_WinnerGroupCard> {
  final noteController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  Uint8List? imageBytes;

  String? selectedFilePath;
  String? selectedFileName;

  bool get isPaid => widget.group.tickets.every((e) => e.paid);

  Future<void> takePhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) return;

    imageBytes = await image.readAsBytes();

    if (mounted) setState(() {});
  }

  Future<void> pickPhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    imageBytes = await image.readAsBytes();

    if (mounted) setState(() {});
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) return;

    setState(() {
      selectedFilePath = result.files.first.path;
      selectedFileName = result.files.first.name;
    });
  }

  Future<void> markPaid() async {
    if (imageBytes == null && selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phải đính kèm ảnh hoặc file chứng từ")),
      );
      return;
    }

    final now = DateTime.now();

    for (final ticket in widget.group.tickets) {
      ticket.paid = true;
      ticket.paidAt = now;

      ticket.proofImageBytes = imageBytes;
      ticket.proofFile = selectedFilePath;
      ticket.note = noteController.text.trim();

      await ticket.save();
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person, color: colorScheme.primary),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.customerName.isEmpty
                            ? "Không rõ"
                            : group.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (group.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              group.phone,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.schedule,
                        size: 14,
                        color: isPaid ? Colors.green[700] : Colors.orange[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? "Đã thanh toán" : "Chưa thanh toán",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPaid
                              ? Colors.green[700]
                              : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// THỐNG KÊ
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    "Loại A",
                    "${group.totalA}",
                    Icons.payments_outlined,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox(
                    "Loại B",
                    "${group.totalB}",
                    Icons.stars_outlined,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox(
                    "Tổng Mã",
                    "${group.tickets.length}",
                    Icons.receipt_long_outlined,
                    colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "TỔNG TIỀN PHẢI TRẢ",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${money(group.totalPayout)} đ",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Danh sách mã sinh lời",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            ...group.tickets.map((t) {
              final typeColor = t.ticketType == "A"
                  ? Colors.indigo
                  : Colors.teal;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: typeColor.withValues(alpha: 0.15),
                      child: Text(
                        t.ticketType,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mã ${t.winningNumber}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "Giá trị ${money(t.orderValue)} đ",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${money(t.payoutAmount)} đ",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (!isPaid) ...[
              const Divider(height: 28),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: takePhoto,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text("Chụp ảnh"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  OutlinedButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.photo, size: 18),
                    label: const Text("Chọn ảnh"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  OutlinedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text("File"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              if (imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 220,
                        height: 220,
                        color: Colors.grey.shade200,
                        child: Image.memory(imageBytes!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),

              if (selectedFileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          selectedFileName!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: "Ghi chú",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: markPaid,
                  icon: const Icon(Icons.check),
                  label: Text(
                    "THANH TOÁN ${money(group.totalPayout)} đ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),

              if (group.tickets.first.proofImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    group.tickets.first.proofImageBytes!,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),

              if (group.tickets.first.proofFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          group.tickets.first.proofFile!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
