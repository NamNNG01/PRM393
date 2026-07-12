import 'package:flutter/material.dart';

class SettlementReportScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const SettlementReportScreen({super.key, required this.result});

  String _formatMoney(dynamic value) {
    if (value == null) return "0 đ";
    if (value is num) {
      final digits = value.toStringAsFixed(0);
      final buffer = StringBuffer();
      final isNegative = digits.startsWith('-');
      final clean = isNegative ? digits.substring(1) : digits;

      for (int i = 0; i < clean.length; i++) {
        final posFromEnd = clean.length - i;
        buffer.write(clean[i]);
        if (posFromEnd > 1 && posFromEnd % 3 == 1) {
          buffer.write('.');
        }
      }
      return "${isNegative ? '-' : ''}${buffer.toString()} đ";
    }
    final parsed = double.tryParse(value.toString());
    if (parsed != null) {
      return _formatMoney(parsed);
    }
    return "${value.toString()} đ";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isProfit = result["profit"] as bool;
    final type = result["type"] as String;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight + 12,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      "Báo cáo bồi hoàn",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 4,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon trạng thái lớn
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isProfit
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isProfit
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: isProfit ? Colors.green[600] : Colors.red[600],
                    size: 40,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isProfit ? "LỢI NHUẬN CÒN LẠI" : "SỐ TIỀN THÂM HỤT",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatMoney(result["remaining"] * 1000),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isProfit ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 1: Thông tin chung
                _sectionHeader("Thông tin chung"),
                _row("Loại vé", "Vé Loại $type"),
                _row("Mã sản phẩm", result["productCode"].toString()),
                if (type == "B")
                  _row("Hệ số bồi hoàn", result["multiplier"].toString()),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),

                // Section 2: Thông số bồi hoàn
                _sectionHeader("Thông số bồi hoàn"),
                _row(
                  type == "A" ? "Số lượng giữ lại" : "Số điểm giữ lại",
                  type == "A"
                      ? "${_formatMoney(result["retained"] * 1000)}"
                      : "${result["retained"]} điểm",
                ),
                if (type == "B")
                  _row("Giá bán / điểm", _formatMoney(result["ticketPrice"])),
                _row("Tỉ lệ bồi hoàn", "${result["refundRate"]}"),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),

                // Section 3: Chi tiết tài chính
                _sectionHeader("Chi tiết tài chính"),
                _row(
                  "Tổng tiền ban đầu (giữ + hồng)",
                  _formatMoney(result["totalRetained"] * 1000),
                ),
                _row(
                  "Tiền phải bồi hoàn",
                  _formatMoney(result["refundMoney"] * 1000),
                  valueColor: Colors.red[700],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),

                _row(
                  "Còn lại (Sau bồi hoàn)",
                  _formatMoney(result["remaining"] * 1000),
                  isHighlight: true,
                  valueColor: isProfit ? Colors.green[700] : Colors.red[700],
                ),

                const SizedBox(height: 28),

                // Banner kết luận
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isProfit
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isProfit
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isProfit ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isProfit
                              ? "Sau khi bồi hoàn, đại lý vẫn bảo toàn được lợi nhuận."
                              : "Sau khi bồi hoàn, tổng thu chi bị âm (đại lý bị lỗ).",
                          style: TextStyle(
                            fontSize: 14,
                            color: isProfit
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _row(
    String title,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
