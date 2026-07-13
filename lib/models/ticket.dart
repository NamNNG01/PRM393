import 'package:hive/hive.dart';

part 'ticket.g.dart';

@HiveType(typeId: 4)
class Ticket extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String type; // A hoặc B

  @HiveField(3)
  double totalValue;

  @HiveField(4)
  String businessDate;

  @HiveField(5)
  bool settled;

  @HiveField(6)
  DateTime createdAt;

  Ticket({
    required this.id,
    required this.customerId,
    required this.type,
    required this.totalValue,
    required this.businessDate,
    required this.settled,
    required this.createdAt,
  });
}
