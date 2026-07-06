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
    final totalUnits = data.values.fold(0, (a, b) => a + b);

    /// Tổng doanh thu
    final totalRevenue = totalUnits * ticketPrice;

    /// Tổng hoa hồng đại lý nhận được
    final totalCommission = totalUnits * commissionPerPoint;

    /// Quỹ dùng để chịu rủi ro
    final insuranceFund = totalCommission;

    /// Số điểm tối đa được giữ trên mỗi mã
    final cap = insuranceFund / (refundRate * maxRisk);

    final retainPerCode = cap.floor();

    final Map<String, int> retained = {};
    final Map<String, int> forwarded = {};

    data.forEach((order, unit) {
      if (unit <= retainPerCode) {
        retained[order.productCode] = unit;
        forwarded[order.productCode] = 0;
      } else {
        retained[order.productCode] = retainPerCode;
        forwarded[order.productCode] = unit - retainPerCode;
      }
    });

    /// Tổng điểm giữ
    final totalRetainedUnits = retained.values.fold(0, (a, b) => a + b);

    /// Tổng điểm chuyển
    final totalForwardedUnits = forwarded.values.fold(0, (a, b) => a + b);

    /// Quy đổi tiền
    final retainedMoney = totalRetainedUnits * ticketPrice;

    final forwardedMoney = totalForwardedUnits * ticketPrice;

    /// Hoa hồng trên phần chuyển chủ
    final commissionMoney = totalForwardedUnits * commissionPerPoint;

    /// Thực chuyển chủ
    final actualPayment = forwardedMoney - commissionMoney;
    final cam = retainedMoney + commissionMoney;

    return {
      "tongDoanhThu": totalRevenue.floor(),

      "giaGiuMoiCon": retainPerCode,

      "tongGiuLai": retainedMoney.floor(),

      "chi_tiết_giữ_lại": retained,

      "chi_tiết_chuyển": forwarded,

      "tongChuyen": forwardedMoney.floor(),

      "hoa_hồng": commissionMoney.floor(),

      "tongThucChuyen": actualPayment.floor(),

      "cam": cam.floor(),
    };
  }
}
