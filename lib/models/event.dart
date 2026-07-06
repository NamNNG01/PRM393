import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 2)
class Event extends HiveObject {
  @HiveField(0)
  String productCode;

  @HiveField(1)
  String type;

  @HiveField(2)
  int multiplier;

  Event({
    required this.productCode,
    required this.type,
    required this.multiplier,
  });
}