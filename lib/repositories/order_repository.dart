import 'package:hive/hive.dart';
import '../hive/hive_boxes.dart';
import '../models/order.dart';

class OrderRepository {
  final Box<Order> _box = Hive.box<Order>(HiveBoxes.orderBox);

  List<Order> getAll() => _box.values.toList();

  Future<void> add(Order order) async {
    await _box.add(order);
  }

  Future<void> delete(int index) async {
    await _box.deleteAt(index);
  }

  Future<void> importOrders(Map<String, num> data, String type) async {
    final existing = _box.values.toList();

    for (final entry in data.entries) {
      final code = entry.key;
      final value = entry.value;

      bool found = false;

      for (int i = 0; i < existing.length; i++) {
        final o = existing[i];

        if (o.productCode == code && o.type == type) {
          found = true;

          final updated = Order(
            productCode: o.productCode,
            type: o.type,
            amount: type == "A" ? o.amount + value.toDouble() : o.amount,
            unit: type == "B" ? o.unit + value.toInt() : o.unit,
            createdAt: o.createdAt,
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
          ),
        );
      }
    }
  }
}
