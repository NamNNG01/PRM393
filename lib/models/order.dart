import 'package:hive/hive.dart';

part 'order.g.dart';

@HiveType(typeId: 0)
class Order extends HiveObject {
  @HiveField(0)
  String productCode;

  @HiveField(1)
  String type;

  @HiveField(2)
  double amount;

  @HiveField(3)
  int unit;

  @HiveField(4)
  DateTime createdAt;

  Order({
    required this.productCode,
    required this.type,
    required this.amount,
    required this.unit,
    required this.createdAt,
  });
}