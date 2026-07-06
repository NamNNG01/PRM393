import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  final Map<String, dynamic> resultA;
  final Map<String, dynamic> resultB;

  const ReportScreen({super.key, required this.resultA, required this.resultB});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báo cáo tài chính")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("TYPE A"),
            _buildCard([
              _row("Tổng doanh thu", resultA["tongDoanhThu"]),

              _row("Giữ lại mỗi con", "${resultA["giaGiuMoiCon"]}"),
              _row("Tổng giữ lại", "${resultA["tongGiuLai"]}"),
              _mapSection(
                "Chi tiết giữ lại",
                resultA["chi_tiết_giữ_lại"] ?? {},
              ),

              _mapSection("Chi tiết chuyển", resultA["chi_tiết_chuyển"] ?? {}),

              const Divider(),

              _row("Tổng chuyển", resultA["tongChuyen"]),

              _row("Hoa hồng", resultA["hoa_hong"]),

              _row("Tổng thực chuyển", resultA["tongThucChuyen"]),
              _row("Tổng cầm (hoa hồng + giữ lại)", resultA["cam"]),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle("TYPE B"),
            _buildCard([
              _row("Tổng doanh thu", resultB["tongDoanhThu"]),

              _row("Giữ lại mỗi mã", "${resultB["giaGiuMoiCon"]} điểm"),

              _row("Tổng giữ lại", resultB["tongGiuLai"]),

              _mapSection(
                "Chi tiết giữ lại",
                resultB["chi_tiết_giữ_lại"] ?? {},
              ),

              _mapSection("Chi tiết chuyển", resultB["chi_tiết_chuyển"] ?? {}),

              const Divider(),

              _row("Tổng chuyển", resultB["tongChuyen"]),

              _row("Hoa hồng", resultB["hoa_hồng"]),

              _row("Tổng thực chuyển", resultB["tongThucChuyen"]),

              _row("Tổng cầm (hoa hồng + giữ lại)", resultB["cam"]),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            _format(value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _mapSection(String title, Map? data) {
    final safeData = data ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        if (safeData.isEmpty)
          const Text("Không có dữ liệu")
        else
          ...safeData.entries.map((e) => Text("${e.key}: ${_format(e.value)}")),
      ],
    );
  }

  String _format(dynamic value) {
    if (value == null) return "0";
    if (value is double) return value.floor().toString();
    return value.toString();
  }
}
