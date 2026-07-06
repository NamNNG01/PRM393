import 'package:hive/hive.dart';

part 'configuration.g.dart';

@HiveType(typeId: 1)
class Configuration extends HiveObject {
  @HiveField(0)
  double ticketPriceA;

  @HiveField(1)
  double refundRateA;

  @HiveField(2)
  double commissionRateA;

  @HiveField(3)
  double ticketPriceB;

  @HiveField(4)
  double refundRateB;

  @HiveField(5)
  double commissionPerPointB;

  @HiveField(6)
  double maxRiskMultiplier;

  Configuration({
    required this.ticketPriceA,
    required this.refundRateA,
    required this.commissionRateA,
    required this.ticketPriceB,
    required this.refundRateB,
    required this.commissionPerPointB,
    required this.maxRiskMultiplier,
  });

  /// DEFAULT CONFIG
  factory Configuration.defaultConfig() {
    return Configuration(
      ticketPriceA: 1,
      refundRateA: 80,
      commissionRateA: 0.3,
      ticketPriceB: 23,
      refundRateB: 80,
      commissionPerPointB: 1,
      maxRiskMultiplier: 2,
    );
  }
}
