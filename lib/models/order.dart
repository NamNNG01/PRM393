import 'package:hive/hive.dart';

part 'order.g.dart';

@HiveType(typeId: 0)
class Order extends HiveObject {
  /// mã sản phẩm
  @HiveField(0)
  String productCode;

  /// A hoặc B
  @HiveField(1)
  String type;

  /// tiền (A)
  @HiveField(2)
  double amount;

  /// điểm (B)
  @HiveField(3)
  int unit;

  /// ngày tạo
  @HiveField(4)
  DateTime createdAt;

  /// ticket chứa order này
  @HiveField(5)
  String ticketId;

  /// khách hàng
  @HiveField(6)
  String customerId;

  /// ngày nghiệp vụ
  @HiveField(7)
  String businessDate;

  Order({
    required this.productCode,
    required this.type,
    required this.amount,
    required this.unit,
    required this.createdAt,
    required this.ticketId,
    required this.customerId,
    required this.businessDate,
  });
}