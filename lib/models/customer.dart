import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 2)
class Customer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;


  @HiveField(3)
  String note;

  @HiveField(4)
  DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.createdAt,
  });
}