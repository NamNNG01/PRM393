import 'package:hive/hive.dart';

part 'winning_result.g.dart';

@HiveType(typeId: 8)
class WinningResult extends HiveObject {
  @HiveField(0)
  String businessDate;

  @HiveField(1)
  String ticketType;

  @HiveField(2)
  String winningNumbers;

  WinningResult({
    required this.businessDate,
    required this.ticketType,
    required this.winningNumbers,
  });
}