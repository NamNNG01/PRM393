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

import '../repositories/order_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/winning_repository.dart';

import '../utils/date_util.dart';

class WinningScreen extends StatefulWidget {
  const WinningScreen({super.key});

  @override
  State<WinningScreen> createState() => _WinningScreenState();
}

class _WinningScreenState extends State<WinningScreen> {
  final winningController = TextEditingController();

  final orderRepo = OrderRepository();
  final customerRepo = CustomerRepository();
  final ticketRepo = TicketRepository();
  final winningRepo = WinningRepository();
  late Configuration config;

  String selectedType = "A";
  List<WinningTicket> winners = [];

  Future<void> findWinner() async {
    final input = winningController.text.trim();

    if (input.isEmpty) return;

    final today = DateUtil.today();

    final orders = orderRepo.getByBusinessDate(today);

    if (selectedType == "A") {
      final existedA = winningRepo
          .getByDate(today)
          .any((e) => e.ticketType == "A");

      if (existedA) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Loại A hôm nay đã xác nhận rồi")),
        );
        return;
      }

      final number = input;

      final matched = orders.where(
        (o) => o.type == "A" && o.productCode == number,
      );

      for (final Order order in matched) {
        final payout = order.amount * config.refundRateA;

        await winningRepo.add(
          WinningTicket(
            ticketId: order.ticketId,
            customerId: order.customerId,
            businessDate: today,
            winningNumber: number,
            ticketType: "A",
            orderValue: order.amount,
            payoutAmount: payout,
          ),
        );
      }
    } else {
      final numbers = input.split(",").map((e) => e.trim()).toList();

      for (final number in numbers) {
        final matched = orders.where(
          (o) => o.type == "B" && o.productCode == number,
        );

        for (final Order order in matched) {
          final payout = order.unit * config.refundRateB * 1000;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác nhận vé trúng")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: "A", child: Text("Loại A")),
                    DropdownMenuItem(value: "B", child: Text("Loại B")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedType = v!;
                    });
                  },
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: winningController,
                  decoration: InputDecoration(
                    labelText: selectedType == "A"
                        ? "Số trúng (00-99)"
                        : "Nhiều số (vd: 12,34,56)",
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: winners.isEmpty
                ? const Center(child: Text("Chưa có vé trúng"))
                : ListView.builder(
                    itemCount: winners.length,
                    itemBuilder: (_, index) {
                      final item = winners[index];

                      final customer = customerRepo.getById(item.customerId);

                      return _WinnerCard(
                        ticket: item,
                        customerName: customer?.name ?? "",
                        phone: customer?.phone ?? "",
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WinnerCard extends StatefulWidget {
  final WinningTicket ticket;
  final String customerName;
  final String phone;

  const _WinnerCard({
    required this.ticket,
    required this.customerName,
    required this.phone,
  });

  @override
  State<_WinnerCard> createState() => _WinnerCardState();
}

class _WinnerCardState extends State<_WinnerCard> {
  final noteController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  XFile? selectedImage;

  String? selectedFilePath;
  String? selectedFileName;

  Uint8List? imageBytes;
  Future<void> takePhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) return;

    imageBytes = await image.readAsBytes();

    setState(() {
      selectedImage = image;
    });
  }

  Future<void> pickPhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    imageBytes = await image.readAsBytes();

    setState(() {
      selectedImage = image;
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null) return;

    setState(() {
      selectedFilePath = result.files.first.path;
      selectedFileName = result.files.first.name;
    });
  }

  Future<void> markPaid() async {
    final hasImage = selectedImage != null;
    final hasFile = selectedFilePath != null;

    if (!hasImage && !hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phải đính kèm ảnh hoặc file chứng từ")),
      );
      return;
    }

    widget.ticket.paid = true;

    widget.ticket.paidAt = DateTime.now();

    widget.ticket.proofImageBytes = imageBytes;
    widget.ticket.proofFile = selectedFilePath;

    widget.ticket.note = noteController.text.trim();

    await widget.ticket.save();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(widget.phone),

            const SizedBox(height: 8),

            Text("Ticket: ${t.ticketId}"),

            Text("Số trúng: ${t.winningNumber}"),
            const SizedBox(height: 6),

            Text("Loại vé: ${t.ticketType}"),

            Text(
              "Giá trị vé: "
              "${t.orderValue.toStringAsFixed(0)}",
            ),

            Text(
              "Tiền phải trả: "
              "${t.payoutAmount.toStringAsFixed(0)} đ",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text("Ngày trúng: ${t.businessDate}"),

            const SizedBox(height: 10),

            if (t.paid)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "✅ Đã thanh toán",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text("Thời gian: ${t.paidAt}"),

                  if (t.proofImageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Image.memory(
                            t.proofImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  if (t.proofFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("📎 ${t.proofFile}"),
                    ),

                  if ((t.note ?? "").isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(t.note!),
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        label: const Text("Đính kèm file"),
                      ),
                    ],
                  ),

                  if (imageBytes != null)
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.memory(imageBytes!, fit: BoxFit.cover),
                    ),

                  if (selectedFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "📎 $selectedFileName",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Ghi chú (tuỳ chọn)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: markPaid,
                      icon: const Icon(Icons.check),
                      label: const Text("XÁC NHẬN THANH TOÁN"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
