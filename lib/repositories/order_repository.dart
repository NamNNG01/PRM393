import 'package:hive/hive.dart';

import '../hive/hive_boxes.dart';
import '../models/order.dart';
import '../utils/date_util.dart';

class OrderRepository {
  final Box<Order> _box = Hive.box<Order>(HiveBoxes.orderBox);

  List<Order> getAll() {
    final today = DateUtil.today();

    return _box.values.where((e) => e.businessDate == today).toList();
  }

  List<Order> getTodayOrders() {
    return _box.values
        .where((e) => e.businessDate == DateUtil.today())
        .toList();
  }

  Future<void> add(Order order) async {
    await _box.add(order);
  }

  Future<void> delete(int index) async {
    await _box.deleteAt(index);
  }

  /// ==========================
  /// Import theo Ticket
  /// ==========================
  Future<void> importOrders({
    required Map<String, num> data,
    required String type,
    required String ticketId,
    required String customerId,
  }) async {
    final today = DateUtil.today();

    final existing = _box.values.toList();

    for (final entry in data.entries) {
      final code = entry.key;
      final value = entry.value;

      bool found = false;

      for (int i = 0; i < existing.length; i++) {
        final o = existing[i];

        /// Chỉ cộng dồn trong cùng ticket
        if (o.productCode == code && o.type == type && o.ticketId == ticketId) {
          found = true;

          final updated = Order(
            productCode: o.productCode,

            type: o.type,

            amount: type == "A" ? o.amount + value.toDouble() : o.amount,

            unit: type == "B" ? o.unit + value.toInt() : o.unit,

            createdAt: o.createdAt,

            ticketId: o.ticketId,

            customerId: o.customerId,

            businessDate: o.businessDate,
          );

          await _box.putAt(i, updated);

          break;
        }
      }

      if (!found) {
        await _box.add(
          Order(
            productCode: code,

            type: type,

            amount: type == "A" ? value.toDouble() : 0,

            unit: type == "B" ? value.toInt() : 0,

            createdAt: DateTime.now(),

            ticketId: ticketId,

            customerId: customerId,

            businessDate: today,
          ),
        );
      }
    }
  }

  /// ==========================
  /// Lấy theo Ticket
  /// ==========================
  List<Order> getByTicket(String ticketId) {
    return _box.values.where((e) => e.ticketId == ticketId).toList();
  }

  /// ==========================
  /// Lấy theo Customer
  /// ==========================
  List<Order> getByCustomer(String customerId) {
    return _box.values.where((e) => e.customerId == customerId).toList();
  }

  /// ==========================
  /// Lấy theo ngày
  /// ==========================
  List<Order> getByBusinessDate(String businessDate) {
    return _box.values.where((e) => e.businessDate == businessDate).toList();
  }
}
