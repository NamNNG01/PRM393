import 'package:hive/hive.dart';

import '../hive/hive_boxes.dart';
import '../models/ticket.dart';

class TicketRepository {
  final Box<Ticket> _box = Hive.box<Ticket>(HiveBoxes.ticketBox);

  /// ======================
  /// Lấy tất cả phiếu
  /// ======================
  List<Ticket> getAll() {
    final tickets = _box.values.toList();

    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return tickets;
  }

  /// ======================
  /// Lấy theo ngày
  /// ======================
  List<Ticket> getByDate(String businessDate) {
    return _box.values.where((e) => e.businessDate == businessDate).toList();
  }

  /// ======================
  /// Lấy theo khách
  /// ======================
  List<Ticket> getByCustomer(String customerId) {
    return _box.values.where((e) => e.customerId == customerId).toList();
  }

  /// ======================
  /// Lấy theo ID
  /// ======================
  Ticket? getById(String id) {
    try {
      return _box.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// ======================
  /// Tạo phiếu mới
  /// ======================
  Future<Ticket> createTicket({
    required String customerId,
    required String businessDate,
    required String type,
    required double totalValue,
  }) async {
    final ticket = Ticket(
      id: _generateId(),
      customerId: customerId,
      type: type,
      totalValue: totalValue,
      businessDate: businessDate,
      settled: false,
      createdAt: DateTime.now(),
    );

    await _box.add(ticket);

    return ticket;
  }

  /// ======================
  /// Update tổng tiền
  /// ======================
  Future<void> updateSummary({
    required String ticketId,
    required String type,
    required double totalValue,
  }) async {
    final ticket = getById(ticketId);

    if (ticket == null) return;

    ticket.type = type;
    ticket.totalValue = totalValue;

    await ticket.save();
  }

  /// ======================
  /// Đánh dấu bồi hoàn
  /// ======================
  Future<void> markSettled(String ticketId) async {
    final ticket = getById(ticketId);

    if (ticket == null) return;

    ticket.settled = true;

    await ticket.save();
  }

  /// ======================
  /// Xóa phiếu
  /// ======================
  Future<void> delete(Ticket ticket) async {
    await ticket.delete();
  }

  /// ======================
  /// Sinh ID
  /// ======================
  String _generateId() {
    final count = _box.length + 1;

    return "T${count.toString().padLeft(6, '0')}";
  }
}
