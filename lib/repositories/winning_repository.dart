import 'package:hive/hive.dart';

import '../hive/hive_boxes.dart';
import '../models/winning_ticket.dart';

class WinningRepository {
  final Box<WinningTicket> _box = Hive.box<WinningTicket>(HiveBoxes.winningBox);

  List<WinningTicket> getAll() {
    return _box.values.toList();
  }

  List<WinningTicket> getByCustomer(String customerId) {
    return _box.values.where((e) => e.customerId == customerId).toList();
  }

  List<WinningTicket> getByDate(String businessDate) {
    return _box.values.where((e) => e.businessDate == businessDate).toList();
  }

  WinningTicket? getByTicketId(String ticketId) {
    try {
      return _box.values.firstWhere((e) => e.ticketId == ticketId);
    } catch (_) {
      return null;
    }
  }

  WinningTicket? findByTicket(String ticketId) {
    try {
      return _box.values.firstWhere((e) => e.ticketId == ticketId);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(WinningTicket ticket) async {
    await _box.add(ticket);
  }
}
