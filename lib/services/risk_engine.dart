import '../models/order.dart';
import 'config_service.dart';

class RiskEngine {
  final configService = ConfigService();

  /// TYPE A
  Map<String, dynamic> processTypeA(Map<Order, double> data) {
    final config = configService.getConfig();

    final commissionRate = config.commissionRateA;
    final refundRate = config.refundRateA;

    final totalRevenue = data.values.fold(0.0, (a, b) => a + b);

    final insuranceFund = totalRevenue * commissionRate;

    final cap = insuranceFund / refundRate;

    final Map<String, int> retained = {};
    final Map<String, int> forwarded = {};

    data.forEach((order, value) {
      final v = value.floor();
      final c = cap.floor();

      int r;
      int f;

      if (v <= c) {
        r = v;
        f = 0;
      } else {
        r = c;
        f = v - c;
      }

      retained[order.productCode] = r;
      forwarded[order.productCode] = f;
    });

    final totalRetained = retained.values.fold(0, (a, b) => a + b);

    final totalForwarded = forwarded.values.fold(0, (a, b) => a + b);

    final commissionMoney = (totalForwarded * commissionRate).floor();

    final supplierPayment = totalForwarded - commissionMoney;

    /// Tổng tiền đại lý thực giữ
    final cam = totalRetained + commissionMoney;
    return {
      "tongDoanhThu": totalRevenue.floor(),

      "giaGiuMoiCon": cap.floor(),
      "tongGiuLai": totalRetained,

      "chi_tiết_giữ_lại": retained,
      "chi_tiết_chuyển": forwarded,

      "tongChuyen": totalForwarded,
      "hoa_hong": commissionMoney,
      "tongThucChuyen": supplierPayment,
      "cam": cam,
    };
  }

  /// TYPE B
  Map<String, dynamic> processTypeB(Map<Order, int> data) {
    final config = configService.getConfig();

    final ticketPrice = config.ticketPriceB;
    final refundRate = config.refundRateB;
    final commissionPerPoint = config.commissionPerPointB;
    final maxRisk = config.maxRiskMultiplier;

    /// Tổng số điểm

    /// Tổng doanh thu
    final totalRevenue = data.values.fold<int>(0, (a, b) => a + b);

    /// Tổng hoa hồng đại lý nhận được
    final totalPoint = totalRevenue / ticketPrice;

    /// Tổng hoa hồng
    final totalCommission = totalPoint * commissionPerPoint;

    /// Quỹ dùng để chịu rủi ro
    final insuranceFund = totalCommission;

    /// Số điểm tối đa được giữ trên mỗi mã
    final cap = insuranceFund / (refundRate * maxRisk);

    final retainMoneyPerCode = (cap * ticketPrice);

    final Map<String, double> retained = {};
    final Map<String, double> forwarded = {};
    data.forEach((order, money) {
      final value = money.toDouble();

      if (value <= retainMoneyPerCode) {
        retained[order.productCode] = value;
        forwarded[order.productCode] = 0;
      } else {
        retained[order.productCode] = retainMoneyPerCode;
        forwarded[order.productCode] = value - retainMoneyPerCode;
      }
    });

    final totalRetainedMoney = retained.values.fold<double>(0, (a, b) => a + b);

    final totalForwardedMoney = forwarded.values.fold<double>(
      0,
      (a, b) => a + b,
    );

    /// Quy đổi phần chuyển sang điểm để tính hoa hồng
    final forwardedPoint = totalForwardedMoney / ticketPrice;

    /// Hoa hồng chỉ tính trên phần chuyển
    final commissionMoney = forwardedPoint * commissionPerPoint;

    /// Thực chuyển
    final actualPayment = totalForwardedMoney - commissionMoney;

    final cam = totalRetainedMoney + commissionMoney;

    return {
      "tongDoanhThu": totalRevenue,

      "giaGiuMoiCon": retainMoneyPerCode,

      "tongGiuLai": totalRetainedMoney,

      "chi_tiết_giữ_lại": retained,

      "chi_tiết_chuyển": forwarded,

      "tongChuyen": totalForwardedMoney,

      "hoa_hồng": commissionMoney,

      "tongThucChuyen": actualPayment,

      "cam": cam,
    };
  }
}
