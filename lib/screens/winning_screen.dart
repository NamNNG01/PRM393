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

  Future<void> findWinner() async {
    bool isValidNumber(String value) {
      return RegExp(r'^\d{2}$').hasMatch(value);
    }

    final input = winningController.text.trim();

    if (input.isEmpty) return;

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
          const SnackBar(content: Text("Số trúng phải từ 00 đến 99")),
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
      final numbers = input
          .split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      if (numbers.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Phải nhập ít nhất 1 số")));
        return;
      }

      for (final n in numbers) {
        if (!isValidNumber(n)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Số không hợp lệ: $n")));
          return;
        }
      }
      await winningResultRepo.addNumbers(businessDate: today, numbers: numbers);
      for (final number in numbers) {
        final existed = winningRepo
            .getByDate(today)
            .any((e) => e.ticketType == "B" && e.winningNumber == number);

        if (existed) continue;
        final matched = orders.where(
          (o) => o.type == "B" && o.productCode == number,
        );

        for (final Order order in matched) {
          final payout = order.unit * config.refundRateB;

          final orderValue = order.unit * config.ticketPriceB;

          await winningRepo.add(
            WinningTicket(
              ticketId: order.ticketId,
              customerId: order.customerId,
              businessDate: today,
              winningNumber: number,
              ticketType: "B",
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
  }

  @override
  Widget build(BuildContext context) {
    final groups = buildGroups();
    return Scaffold(
      appBar: AppBar(title: const Text("Xác nhận vé trúng")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Loại vé",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "A", child: Text("Loại A")),
                      DropdownMenuItem(value: "B", child: Text("Loại B")),
                    ],
                    onChanged: (v) {
                      final type = v!;

                      setState(() {
                        selectedType = type;

                        final result = winningResultRepo.getResult(
                          DateUtil.today(),
                          type,
                        );

                        winningController.text = result?.winningNumbers ?? "";
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: winningController,

                    enabled:
                        winningResultRepo.getResult(
                          DateUtil.today(),
                          selectedType,
                        ) ==
                        null,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: selectedType == "A"
                          ? "Số trúng (00-99)"
                          : "12,34,56",
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                ElevatedButton(
                  onPressed: findWinner,
                  child: const Text("Xác nhận"),
                ),
              ],
            ),
          ),

          Expanded(
            child: groups.isEmpty
                ? const Center(child: Text("Chưa có vé trúng"))
                : ListView.builder(
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      Text(group.phone),
                    ],
                  ),
                ),

                Chip(
                  backgroundColor: isPaid
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  label: Text(isPaid ? "Đã thanh toán" : "Chưa thanh toán"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// THỐNG KÊ
            Row(
              children: [
                Expanded(child: _statBox("Loại A", "${group.totalA}")),

                const SizedBox(width: 8),

                Expanded(child: _statBox("Loại B", "${group.totalB}")),

                const SizedBox(width: 8),

                Expanded(child: _statBox("Tổng vé", "${group.tickets.length}")),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    "TỔNG TIỀN PHẢI TRẢ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${money(group.totalPayout)} đ",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Danh sách mã trúng",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...group.tickets.map(
              (t) => Card(
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  title: Text("Mã ${t.winningNumber}"),
                  subtitle: Text(
                    "Loại ${t.ticketType} • "
                    "Giá trị ${money(t.orderValue)} đ",
                  ),
                  trailing: Text(
                    "${money(t.payoutAmount)} đ",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            if (!isPaid) ...[
              const Divider(height: 24),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Chụp ảnh"),
                  ),

                  OutlinedButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.photo),
                    label: const Text("Chọn ảnh"),
                  ),

                  OutlinedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text("File"),
                  ),
                ],
              ),

              if (imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              if (selectedFileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("📎 $selectedFileName"),
                ),

              const SizedBox(height: 12),

              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Ghi chú",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: markPaid,
                  icon: const Icon(Icons.check),
                  label: Text("THANH TOÁN ${money(group.totalPayout)} đ"),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),

              if (group.tickets.first.proofImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    group.tickets.first.proofImageBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              if (group.tickets.first.proofFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("📎 ${group.tickets.first.proofFile}"),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
