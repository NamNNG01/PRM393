import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  final Map<String, dynamic> resultA;
  final Map<String, dynamic> resultB;

  const ReportScreen({super.key, required this.resultA, required this.resultB});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _formatMoney(dynamic value) {
    if (value == null) return "0 đ";
    final num val = value is num
        ? value
        : (double.tryParse(value.toString()) ?? 0);
    final clean = val.floor().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      final posFromEnd = clean.length - i;
      buffer.write(clean[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return "${buffer.toString()} đ";
  }

  String _formatPoint(dynamic value) {
    if (value == null) return "0 điểm";
    final num val = value is num
        ? value
        : (double.tryParse(value.toString()) ?? 0);
    final clean = val.floor().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      final posFromEnd = clean.length - i;
      buffer.write(clean[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return "${buffer.toString()} điểm";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final revA = widget.resultA["tongDoanhThu"] * 1000 ?? 0;
    final revB = widget.resultB["tongDoanhThu"] * 1000 ?? 0;
    final totalRevenue = revA + revB;

    final keptA = widget.resultA["tongGiuLai"] * 1000 ?? 0;
    final keptB = widget.resultB["tongGiuLai"] * 1000 ?? 0;
    final totalKept = keptA + keptB;

    final fwdA = widget.resultA["tongChuyen"] * 1000 ?? 0;
    final fwdB = widget.resultB["tongChuyen"] * 1000 ?? 0;
    final totalForwarded = fwdA + fwdB;

    final commA = widget.resultA["hoa_hong"] * 1000 ?? 0;
    final commB =
        widget.resultB["hoa_hồng"] * 1000 ??
        widget.resultB["hoa_hong"] * 1000 ??
        0;
    final totalCommission = commA + commB;

    final netFwdA = widget.resultA["tongThucChuyen"] * 1000 ?? 0;
    final netFwdB = widget.resultB["tongThucChuyen"] * 1000 ?? 0;
    final totalNetForwarded = netFwdA + netFwdB;

    final holdA = widget.resultA["cam"] * 1000 ?? 0;
    final holdB = widget.resultB["cam"] * 1000 ?? 0;
    final totalHold = holdA + holdB;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            "Báo cáo tài chính",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
              fontSize: 22,
            ),
          ),
          flexibleSpace: Container(
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
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: colorScheme.onPrimary,
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.65),
            indicatorWeight: 4.0,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.analytics_outlined), text: "Tổng quan"),
              Tab(icon: Icon(Icons.payments_outlined), text: "Mã Loại A"),
              Tab(icon: Icon(Icons.stars_outlined), text: "Mã Loại B"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(
              totalRevenue: totalRevenue,
              totalKept: totalKept,
              totalForwarded: totalForwarded,
              totalCommission: totalCommission,
              totalNetForwarded: totalNetForwarded,
              totalHold: totalHold,
              revA: revA,
              revB: revB,
            ),
            _buildTypeATab(colorScheme),
            _buildTypeBTab(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab({
    required num totalRevenue,
    required num totalKept,
    required num totalForwarded,
    required num totalCommission,
    required num totalNetForwarded,
    required num totalHold,
    required num revA,
    required num revB,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TỔNG THU NHẬP ĐẠI LÝ (CẦM)",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatMoney(totalHold),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Bao gồm: ${_formatMoney(totalKept)} giữ lại + ${_formatMoney(totalCommission)} hoa hồng chuyển chủ",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Chỉ số tổng quan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildKpiCard(
                title: "Doanh thu A + B",
                value: _formatMoney(totalRevenue),
                icon: Icons.monetization_on_outlined,
                baseColor: Colors.blue,
              ),
              _buildKpiCard(
                title: "Thực chuyển chủ",
                value: _formatMoney(totalNetForwarded),
                icon: Icons.local_shipping_outlined,
                baseColor: Colors.orange,
              ),
              _buildKpiCard(
                title: "Hoa hồng",
                value: _formatMoney(totalCommission),
                icon: Icons.percent_outlined,
                baseColor: Colors.teal,
              ),
              _buildKpiCard(
                title: "Giữ lại",
                value: _formatMoney(totalKept),
                icon: Icons.security_outlined,
                baseColor: Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildRatioBar(
            retained: totalKept.toDouble(),
            forwarded: totalForwarded.toDouble(),
            retainedLabel: "Tổng giữ lại",
            forwardedLabel: "Tổng chuyển đi",
            retainedColor: Colors.indigo,
            forwardedColor: Colors.orange,
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Phân chia theo Loại hình Mã",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 18),
                _buildBreakdownRow("Mã Loại A (Type A)", revA, Colors.indigo),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildBreakdownRow("Mã Loại B (Type B)", revB, Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String title, num revenue, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        Text(
          _formatMoney(revenue),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTypeATab(ColorScheme colorScheme) {
    final res = widget.resultA;
    final num revenue = res["tongDoanhThu"] * 1000 ?? 0;
    final num keptLimit = res["giaGiuMoiCon"] * 1000 ?? 0;
    final num totalKept = res["tongGiuLai"] * 1000 ?? 0;
    final num totalFwd = res["tongChuyen"] * 1000 ?? 0;
    final num comm = res["hoa_hong"] * 1000 ?? 0;
    final num netFwd = res["tongThucChuyen"] * 1000 ?? 0;
    final num hold = res["cam"] * 1000 ?? 0;
    final Map<String, dynamic> retainedDetails = Map<String, dynamic>.from(
      res["chi_tiết_giữ_lại"] ?? {},
    );
    final Map<String, dynamic> forwardedDetails = Map<String, dynamic>.from(
      res["chi_tiết_chuyển"] ?? {},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildKpiCard(
                title: "Doanh thu Loại A",
                value: _formatMoney(revenue),
                icon: Icons.monetization_on_outlined,
                baseColor: Colors.blue,
              ),
              _buildKpiCard(
                title: "Giữ tối đa / mã",
                value: _formatMoney(keptLimit),
                icon: Icons.tune_outlined,
                baseColor: Colors.deepPurple,
                subtext: "Giới hạn giữ lại",
              ),
              _buildKpiCard(
                title: "Thực chuyển",
                value: _formatMoney(netFwd),
                icon: Icons.send_and_archive_outlined,
                baseColor: Colors.orange,
                subtext: "Hoa hồng: ${_formatMoney(comm)}",
              ),
              _buildKpiCard(
                title: "Thực cầm",
                value: _formatMoney(hold),
                icon: Icons.wallet_outlined,
                baseColor: Colors.green,
                subtext: "Giữ lại + Hoa hồng",
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildRatioBar(
            retained: totalKept.toDouble(),
            forwarded: totalFwd.toDouble(),
            retainedLabel: "Giữ lại",
            forwardedLabel: "Chuyển đi",
            retainedColor: Colors.indigo,
            forwardedColor: Colors.orange,
          ),
          const SizedBox(height: 24),

          _buildDetailTable(
            retained: retainedDetails,
            forwarded: forwardedDetails,
            isTypeA: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBTab(ColorScheme colorScheme) {
    final res = widget.resultB;
    final num revenue = res["tongDoanhThu"] * 1000 ?? 0;
    final num keptLimit = res["giaGiuMoiCon"] * 1000 ?? 0;
    final num totalKept = res["tongGiuLai"] * 1000 ?? 0;
    final num totalFwd = res["tongChuyen"] * 1000 ?? 0;
    final num comm = res["hoa_hồng"] * 1000 ?? res["hoa_hong"] * 1000 ?? 0;
    final num netFwd = res["tongThucChuyen"] * 1000 ?? 0;
    final num hold = res["cam"] * 1000 ?? 0;
    final Map<String, dynamic> retainedDetails = Map<String, dynamic>.from(
      res["chi_tiết_giữ_lại"] ?? {},
    );
    final Map<String, dynamic> forwardedDetails = Map<String, dynamic>.from(
      res["chi_tiết_chuyển"] ?? {},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildKpiCard(
                title: "Doanh thu Loại B",
                value: _formatMoney(revenue),
                icon: Icons.monetization_on_outlined,
                baseColor: Colors.blue,
              ),
              _buildKpiCard(
                title: "Giữ tối đa / mã",
                value: _formatPoint(keptLimit),
                icon: Icons.tune_outlined,
                baseColor: Colors.deepPurple,
                subtext: "Giới hạn điểm giữ lại",
              ),
              _buildKpiCard(
                title: "Thực chuyển",
                value: _formatMoney(netFwd),
                icon: Icons.send_and_archive_outlined,
                baseColor: Colors.orange,
                subtext: "Hoa hồng: ${_formatMoney(comm)}",
              ),
              _buildKpiCard(
                title: "Thực cầm",
                value: _formatMoney(hold),
                icon: Icons.wallet_outlined,
                baseColor: Colors.green,
                subtext: "Giữ lại + Hoa hồng",
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildRatioBar(
            retained: totalKept.toDouble(),
            forwarded: totalFwd.toDouble(),
            retainedLabel: "Giữ lại (tiền)",
            forwardedLabel: "Chuyển đi (tiền)",
            retainedColor: Colors.indigo,
            forwardedColor: Colors.orange,
          ),
          const SizedBox(height: 24),

          _buildDetailTable(
            retained: retainedDetails,
            forwarded: forwardedDetails,
            isTypeA: false,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color baseColor,
    String? subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: baseColor.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: baseColor, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatioBar({
    required double retained,
    required double forwarded,
    required String retainedLabel,
    required String forwardedLabel,
    required Color retainedColor,
    required Color forwardedColor,
  }) {
    final total = retained + forwarded;
    final retainedPct = total > 0 ? (retained / total) : 0.0;
    final forwardedPct = total > 0 ? (forwarded / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tỷ lệ Phân bổ (Giữ lại vs Chuyển đi)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text(
                  "Không có dữ liệu",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (retainedPct > 0)
                      Expanded(
                        flex: (retainedPct * 100).round(),
                        child: Container(color: retainedColor),
                      ),
                    if (forwardedPct > 0)
                      Expanded(
                        flex: (forwardedPct * 100).round(),
                        child: Container(color: forwardedColor),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: retainedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$retainedLabel: ${(retainedPct * 100).toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: forwardedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$forwardedLabel: ${(forwardedPct * 100).toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTable({
    required Map<String, dynamic> retained,
    required Map<String, dynamic> forwarded,
    required bool isTypeA,
  }) {
    final keys = {...retained.keys, ...forwarded.keys}.toList();
    keys.sort();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: [
              Icon(
                Icons.list_alt_rounded,
                color: Colors.blueGrey[700],
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Chi tiết theo mã sản phẩm (${keys.length})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          children: [
            if (keys.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    "Không có dữ liệu",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.grey[150]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.4),
                    2: FlexColumnWidth(1.4),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Text(
                            "Mã SP",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Text(
                            "Giữ lại",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Text(
                            "Chuyển đi",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...keys.map((key) {
                      final rVal = retained[key] * 1000 ?? 0;
                      final fVal = forwarded[key] * 1000 ?? 0;

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blueGrey[800],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            child: Text(
                              isTypeA ? _formatMoney(rVal) : _formatPoint(rVal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            child: Text(
                              isTypeA ? _formatMoney(fVal) : _formatPoint(fVal),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.teal[700],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
