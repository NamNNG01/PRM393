class SettlementService {
  /// =========================
  /// TYPE A
  /// =========================
  Map<String, dynamic> calculateTypeA({
    required Map<String, dynamic> report,
    required String productCode,
    required double refundRate,
  }) {
    final retained = Map<String, int>.from(report["chi_tiết_giữ_lại"] ?? {});

    final retainedAmount = retained[productCode] ?? 0;

    final totalRetainedMoney = report["cam"] as num;
    final refundMoney = retainedAmount * refundRate;

    final remaining = totalRetainedMoney - refundMoney;

    return {
      "type": "A",

      "productCode": productCode,

      "retained": retainedAmount,

      "refundRate": refundRate,

      "refundMoney": refundMoney.floor(),

      "totalRetained": totalRetainedMoney.floor(),

      "remaining": remaining.floor(),

      "profit": remaining >= 0,
    };
  }

  Map<String, dynamic> calculateTypeB({
    required Map<String, dynamic> report,
    required String productCode,
    required double refundRate,
    required int multiplier,
    required double ticketPrice,
  }) {
    final retained = Map<String, int>.from(report["chi_tiết_giữ_lại"] ?? {});

    final retainedUnit = retained[productCode] ?? 0;

    final giaGiuMoiDiem = report["giaGiuMoiCon"] as num;
    final hoaHong = report["hoa_hồng"] as num;

    final tongDiemGiu = retained.values.fold<int>(0, (a, b) => a + b);

    final totalRetainedMoney = hoaHong + giaGiuMoiDiem * tongDiemGiu;

    final refundMoney = retainedUnit * refundRate * multiplier;

    final remaining = totalRetainedMoney - refundMoney;

    return {
      "type": "B",

      "productCode": productCode,

      "retained": retainedUnit,

      "ticketPrice": ticketPrice,

      "refundRate": refundRate,

      "multiplier": multiplier,

      "refundMoney": refundMoney.floor(),

      "totalRetained": totalRetainedMoney.floor(),

      "remaining": remaining.floor(),

      "profit": remaining >= 0,
    };
  }
}
