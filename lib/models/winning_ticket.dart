import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'winning_ticket.g.dart';

@HiveType(typeId: 10)
class WinningTicket extends HiveObject {
  @HiveField(0)
  String ticketId;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String businessDate;

  @HiveField(3)
  String winningNumber;

  @HiveField(4)
  bool paid;

  @HiveField(5)
  DateTime? paidAt;

  @HiveField(6)
  Uint8List? proofImageBytes;

  @HiveField(7)
  String? note;

  @HiveField(8)
  String? proofFile;

  @HiveField(9)
  String ticketType;

  @HiveField(10)
  double orderValue;

  @HiveField(11)
  double payoutAmount;
  @HiveField(12)
  double multiplier;

  WinningTicket({
    required this.ticketId,
    required this.customerId,
    required this.businessDate,
    required this.winningNumber,
    required this.ticketType,
    required this.orderValue,
    required this.payoutAmount,
    this.paid = false,
    this.paidAt,
    this.proofImageBytes,
    this.proofFile,
    this.note,
    this.multiplier = 1,
  });
}
