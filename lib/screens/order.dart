import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/winning_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import '../hive/hive_boxes.dart';
import '../models/order.dart';
import 'import_order.dart';
import 'settings.dart';
import '../services/risk_engine.dart';
import '../repositories/order_repository.dart';
import 'report.dart';
import 'settlement_screen.dart';
import '../utils/date_util.dart';
import '../repositories/customer_repository.dart';
import '../models/configuration.dart';
import '../services/config_service.dart';
import 'customer_list_screen.dart';
import '../services/export_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final configBox = Hive.box<Configuration>(HiveBoxes.configBox);

  static const List<String> _weekdays = [
    "Thứ Hai",
    "Thứ Ba",
    "Thứ Tư",
    "Thứ Năm",
    "Thứ Sáu",
    "Thứ Bảy",
    "Chủ Nhật",
  ];

  String _formatHeaderDate(DateTime dt) {
    final weekday = _weekdays[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return "$weekday, $d/$m/${dt.year}";
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    final money = (value * 1000).round();

    final digits = money.toString();
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

    final result = isNegative ? '-${buffer.toString()}' : buffer.toString();

    return '$resultđ';
  }

  String _buildExportText(List<Order> orders, Configuration config) {
    final typeA = <String, double>{};
    final typeB = <String, int>{};

    for (final o in orders) {
      if (o.type == "A") {
        typeA[o.productCode] = (typeA[o.productCode] ?? 0) + o.amount;
      } else {
        typeB[o.productCode] = (typeB[o.productCode] ?? 0) + o.unit;
      }
    }

    final buffer = StringBuffer();

    final now = DateUtil.selectedDate;

    final dateText =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${(now.year % 100).toString().padLeft(2, '0')}";

    buffer.writeln(" $dateText");
    buffer.writeln("");

    buffer.writeln("LOẠI A");

    double totalA = 0;

    for (final e in typeA.entries) {
      totalA += e.value;

      buffer.writeln("${e.key} : ${_formatNumber(e.value)}");
    }

    final commissionA = totalA * config.commissionRateA;

    buffer.writeln("Tổng A: ${_formatNumber(totalA)}");
    buffer.writeln(
      "Hoa hồng A (${(config.commissionRateA * 100).toStringAsFixed(0)}%): "
      "${_formatNumber(commissionA)}",
    );

    buffer.writeln("");
    buffer.writeln("LOẠI B");

    double totalMoneyB = 0;

    for (final e in typeB.entries) {
      final money = e.value.toDouble();

      totalMoneyB += money;

      buffer.writeln("${e.key} : ${_formatNumber(money)}");
    }

    // Số điểm tương đương để tính hoa hồng
    final totalPointB = totalMoneyB / config.ticketPriceB;

    // Hoa hồng = điểm * tiền hoa hồng mỗi điểm
    final commissionB = totalPointB * config.commissionPerPointB;

    buffer.writeln("Tổng B: ${_formatNumber(totalMoneyB)}");

    buffer.writeln(
      "Hoa hồng B :  "
      "${_formatNumber(commissionB)}",
    );

    final totalRevenue = totalA + totalMoneyB;

    final totalCommission = commissionA + commissionB;

    final netTransfer = totalRevenue - totalCommission;

    buffer.writeln("");
    buffer.writeln("TỔNG DOANH THU: ${_formatNumber(totalRevenue)}");

    buffer.writeln("TỔNG HOA HỒNG: ${_formatNumber(totalCommission)}");

    buffer.writeln("THỰC CHUYỂN: ${_formatNumber(netTransfer)}");

    return buffer.toString();
  }

  Future<void> _copyOrders() async {
    final config = ConfigService().getConfig();

    final orders = OrderRepository().getTodayOrders();

    final text = _buildExportText(orders, config);

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(" Đã lưu vào bộ nhớ tạm")));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final isPast = DateTime(
      DateUtil.selectedDate.year,
      DateUtil.selectedDate.month,
      DateUtil.selectedDate.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20),
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
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight + 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Mã",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatHeaderDate(DateUtil.selectedDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// CHỌN NGÀY
                      _AppBarIconButton(
                        tooltip: "Chọn ngày",
                        icon: Icons.calendar_month,
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateUtil.selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setState(() {
                              DateUtil.selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 6),

                      PopupMenuButton<String>(
                        tooltip: "Báo cáo & bồi hoàn",
                        padding: EdgeInsets.zero,
                        elevation: 6,
                        offset: const Offset(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        onSelected: (value) {
                          final engine = RiskEngine();
                          final repo = OrderRepository();

                          /// chỉ lấy đơn của ngày đang chọn
                          final orders = repo.getTodayOrders();

                          final Map<Order, double> dataA = {};
                          final Map<Order, int> dataB = {};

                          for (final o in orders) {
                            if (o.type == "A") {
                              dataA[o] = o.amount;
                            } else {
                              dataB[o] = o.unit;
                            }
                          }

                          final resultA = engine.processTypeA(dataA);
                          final resultB = engine.processTypeB(dataB);

                          if (value == "report") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportScreen(
                                  resultA: resultA,
                                  resultB: resultB,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettlementScreen(
                                  resultA: resultA,
                                  resultB: resultB,
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          _menuItem(
                            value: "report",
                            icon: Icons.bar_chart_rounded,
                            label: "Báo cáo tài chính",
                            color: Colors.indigo,
                          ),
                          _menuItem(
                            value: "settlement",
                            icon: Icons.request_quote_outlined,
                            label: "Tính bồi hoàn",
                            color: Colors.orange,
                          ),
                        ],
                      ),

                      const SizedBox(width: 6),

                      /// MENU THÊM: gom các mục ít dùng để header luôn vừa màn hình
                      PopupMenuButton<String>(
                        tooltip: "Thêm",
                        padding: EdgeInsets.zero,
                        elevation: 6,
                        offset: const Offset(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == "customers") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerListScreen(),
                              ),
                            );
                          } else if (value == "winning") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WinningScreen(),
                              ),
                            );
                          } else if (value == "settings") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          _menuItem(
                            value: "customers",
                            icon: Icons.people_alt_outlined,
                            label: "Khách hàng",
                            color: Colors.blue,
                          ),
                          _menuItem(
                            value: "winning",
                            icon: Icons.emoji_events_outlined,
                            label: "Mã sinh lời",
                            color: Colors.amber[800]!,
                          ),
                          _menuItem(
                            value: "settings",
                            icon: Icons.settings_outlined,
                            label: "Cài đặt",
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      body: ValueListenableBuilder<Box>(
        valueListenable: Hive.box(ConfigService.boxName).listenable(),
        builder: (context, _, __) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Order>(HiveBoxes.orderBox).listenable(),
            builder: (context, _, __) {
              final orderBox = Hive.box<Order>(HiveBoxes.orderBox);
              final ordersList = OrderRepository().getAll();

              if (ordersList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.15),
                                colorScheme.primary.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.inbox_outlined,
                            size: 56,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Chưa có mã nào",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bắt đầu bằng cách nhập danh sách mã loại A hoặc B",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        if (!isPast) ...[
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ImportOrderScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("Nhập mã"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              final config = ConfigService().getConfig();
              double totalCommission = 0;
              final orders = OrderRepository().getTodayOrders();

              double totalRevenue = 0;

              double totalAmountA = 0;
              double totalAmountB = 0;

              final grouped = <String, num>{};

              // lưu tổng tiền B để cuối tính commission
              double totalPointB = 0;

              for (final o in orders) {
                final revenueValue = o.type == "A"
                    ? o.amount
                    : o.unit.toDouble();
                totalRevenue += revenueValue;

                final groupKey = "${o.type}|${o.productCode}";

                grouped[groupKey] = (grouped[groupKey] ?? 0) + revenueValue;

                if (o.type == "A") {
                  totalAmountA += o.amount;

                  totalCommission += o.amount * config.commissionRateA;
                } else {
                  totalAmountB += o.unit;
                }
              }

              // Sau khi có tổng tiền B mới tính hoa hồng

              totalPointB = totalAmountB / config.ticketPriceB;

              totalCommission += totalPointB * config.commissionPerPointB;
              final transferToUpper =
                  totalAmountA + totalAmountB - totalCommission;
              final exportGrouped = grouped;
              final typeACount = orders.where((e) => e.type == "A").length;
              final typeBCount = orders.where((e) => e.type == "B").length;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: "Tổng số mã",
                            value: "${orders.length}",
                            icon: Icons.receipt_long_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: "Loại A",
                            value: "$typeACount",
                            icon: Icons.payments_outlined,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: "Loại B",
                            value: "$typeBCount",
                            icon: Icons.stars_outlined,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: "Tổng quan"),
                              Tab(text: "Chi tiết"),
                            ],
                          ),

                          Expanded(
                            child: TabBarView(
                              children: [
                                /// TAB TỔNG QUAN
                                _OverviewTab(
                                  grouped: grouped,
                                  totalRevenue: totalRevenue,
                                  commission: totalCommission,
                                  transferToUpper: transferToUpper,
                                  formatNumber: _formatNumber,
                                ),

                                /// TAB CHI TIẾT
                                _DetailTab(
                                  orders: orders,
                                  formatNumber: _formatNumber,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),

      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPast)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.tertiary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImportOrderScreen(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Nhập",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 12),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(cardColor: Colors.white),
              child: PopupMenuButton<String>(
                tooltip: "Xuất dữ liệu",
                elevation: 6,
                offset: const Offset(0, -180),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) async {
                  if (value == "copy") {
                    await _copyOrders();
                  } else {
                    final dateStr = DateUtil.today();
                    final config = ConfigService().getConfig();
                    final orders = OrderRepository().getTodayOrders();
                    if (value == "excel") {
                      await ExportService.exportOrdersToExcel(
                        orders: orders,
                        config: config,
                        date: dateStr,
                      );
                    } else if (value == "pdf") {
                      await ExportService.exportOrdersToPdf(
                        orders: orders,
                        config: config,
                        date: dateStr,
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  _menuItem(
                    value: "copy",
                    icon: Icons.copy,
                    label: "Sao chép",
                    color: Colors.blueGrey,
                  ),
                  _menuItem(
                    value: "excel",
                    icon: Icons.table_view,
                    label: "Xuất Excel",
                    color: Colors.green,
                  ),
                  _menuItem(
                    value: "pdf",
                    icon: Icons.picture_as_pdf,
                    label: "Xuất PDF",
                    color: Colors.red,
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Xuất",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  final Map<String, num> grouped;

  final double totalRevenue;
  final double commission;
  final double transferToUpper;

  final String Function(num) formatNumber;

  const _OverviewTab({
    required this.grouped,
    required this.totalRevenue,
    required this.commission,
    required this.transferToUpper,
    required this.formatNumber,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

abstract class _SortOptionLike {
  String get label;
  IconData get icon;
}

enum _SortOption implements _SortOptionLike {
  valueDesc("Giá trị: Cao → Thấp", Icons.arrow_downward_rounded),
  valueAsc("Giá trị: Thấp → Cao", Icons.arrow_upward_rounded),
  codeAsc("Mã: A → Z", Icons.sort_by_alpha_rounded),
  codeDesc("Mã: Z → A", Icons.sort_by_alpha_rounded);

  @override
  final String label;
  @override
  final IconData icon;

  const _SortOption(this.label, this.icon);
}

enum _OrderSortOption implements _SortOptionLike {
  timeDesc("Mới nhất", Icons.schedule_rounded),
  timeAsc("Cũ nhất", Icons.history_rounded),
  valueDesc("Giá trị: Cao → Thấp", Icons.arrow_downward_rounded),
  valueAsc("Giá trị: Thấp → Cao", Icons.arrow_upward_rounded);

  @override
  final String label;
  @override
  final IconData icon;

  const _OrderSortOption(this.label, this.icon);
}

/// Nút mở menu sắp xếp, dùng chung cho các danh sách trong màn mã
class _SortMenuButton<T extends _SortOptionLike> extends StatelessWidget {
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;

  const _SortMenuButton({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      tooltip: "Sắp xếp",
      padding: EdgeInsets.zero,
      elevation: 6,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      initialValue: value,
      onSelected: onChanged,
      icon: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(Icons.sort_rounded, size: 20, color: colorScheme.primary),
      ),
      itemBuilder: (_) => values.map((option) {
        final selected = option == value;

        return PopupMenuItem<T>(
          value: option,
          child: Row(
            children: [
              Icon(
                option.icon,
                size: 18,
                color: selected ? colorScheme.primary : Colors.grey[600],
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  option.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? colorScheme.primary : Colors.black87,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _OverviewTabState extends State<_OverviewTab> {
  static const String _all = "__all__";
  String selectedType = _all;
  final searchController = TextEditingController();
  String keyword = "";
  _SortOption sortOption = _SortOption.valueDesc;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kw = keyword.toLowerCase().trim();

    final entries = widget.grouped.entries.toList();

    final filteredEntries = entries.where((e) {
      final parts = e.key.split('|');
      final type = parts[0];
      final code = parts[1];

      final matchType = selectedType == _all || type == selectedType;
      final matchCode = kw.isEmpty || code.toLowerCase().contains(kw);
      return matchType && matchCode;
    }).toList();

    switch (sortOption) {
      case _SortOption.valueDesc:
        filteredEntries.sort((a, b) => b.value.compareTo(a.value));
        break;
      case _SortOption.valueAsc:
        filteredEntries.sort((a, b) => a.value.compareTo(b.value));
        break;
      case _SortOption.codeAsc:
        filteredEntries.sort(
          (a, b) => a.key.split('|')[1].compareTo(b.key.split('|')[1]),
        );
        break;
      case _SortOption.codeDesc:
        filteredEntries.sort(
          (a, b) => b.key.split('|')[1].compareTo(a.key.split('|')[1]),
        );
        break;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      children: [
        _MoneyCard(
          title: "Tổng doanh thu",
          value: widget.formatNumber(widget.totalRevenue),
          icon: Icons.monetization_on_outlined,
          color: Colors.blue,
        ),
        const SizedBox(height: 10),
        _MoneyCard(
          title: "Hoa hồng",
          value: widget.formatNumber(widget.commission),
          icon: Icons.percent_outlined,
          color: Colors.teal,
        ),
        const SizedBox(height: 10),
        _MoneyCard(
          title: "Thực chuyển cấp trên",
          value: widget.formatNumber(widget.transferToUpper),
          icon: Icons.send_and_archive_outlined,
          color: Colors.orange,
        ),

        const SizedBox(height: 16),

        _TypeFilterChips(
          selected: selectedType,
          onChanged: (v) => setState(() => selectedType = v),
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => keyword = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Tìm theo mã sản phẩm...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: keyword.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchController.clear();
                            setState(() => keyword = "");
                          },
                        ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SortMenuButton<_SortOption>(
              value: sortOption,
              values: _SortOption.values,
              onChanged: (v) => setState(() => sortOption = v),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (filteredEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text("Không tìm thấy mã sản phẩm")),
          )
        else
          ...filteredEntries.map((e) {
            final parts = e.key.split('|');
            final type = parts[0];
            final code = parts[1];
            final typeColor = type == "A" ? Colors.indigo : Colors.teal;

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: typeColor.withValues(alpha: 0.15),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Loại $type"),
                trailing: Text(
                  widget.formatNumber(e.value),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Hàng chip chọn nhanh Loại A / Loại B / Tất cả
class _TypeFilterChips extends StatelessWidget {
  static const String _all = "__all__";
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeFilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (_all, "Tất cả", Theme.of(context).colorScheme.primary),
      ("A", "Loại A", Colors.indigo),
      ("B", "Loại B", Colors.teal),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final value = opt.$1;
          final label = opt.$2;
          final color = opt.$3;
          final isSelected = selected == value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.08),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Dropdown dạng viên thuốc (pill), rõ ràng là 1 dropdown thay vì trông giống ô nhập text
class _PillDropdown<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final Color accent;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PillDropdown({
    required this.icon,
    required this.value,
    required this.accent,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: accent,
                  size: 20,
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTab extends StatefulWidget {
  final List<Order> orders;

  final String Function(num) formatNumber;

  const _DetailTab({required this.orders, required this.formatNumber});

  @override
  State<_DetailTab> createState() => _DetailTabState();
}

class _DetailTabState extends State<_DetailTab> {
  static const String _all = "__all__";
  final customerRepo = CustomerRepository();
  final searchController = TextEditingController();
  String keyword = "";
  String selectedType = _all;
  _OrderSortOption sortOption = _OrderSortOption.timeDesc;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    return "${_two(dt.day)}/${_two(dt.month)}/${dt.year} "
        "${_two(dt.hour)}:${_two(dt.minute)}";
  }

  /// Hiển thị số thập phân đúng giá trị thực (2.56 giữ nguyên 2.56),
  /// chỉ bỏ phần thập phân khi giá trị là số nguyên (100.0 -> 100).
  String _trimDecimal(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(6);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  /// Sửa số tiền/điểm của 1 mã đã nhập — không cho xóa, chỉ cho sửa,
  /// và bắt buộc phải xác nhận nghiêm túc trước khi lưu vì ảnh hưởng tiền của khách.
  Future<void> _editOrder(BuildContext context, Order order) async {
    final isTypeA = order.type == "A";

    final controller = TextEditingController(
      text: isTypeA ? _trimDecimal(order.amount) : order.unit.toString(),
    );

    final newValue = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Sửa mã ${order.productCode}"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: isTypeA ? "Số tiền (nghìn đồng)" : "Số điểm",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v == null || v <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("Giá trị không hợp lệ")),
                );
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text("Tiếp tục"),
          ),
        ],
      ),
    );

    if (newValue == null) return;
    if (!context.mounted) return;

    final oldDisplay = isTypeA
        ? widget.formatNumber(order.amount)
        : "${order.unit} điểm";
    final newDisplay = isTypeA
        ? widget.formatNumber(newValue)
        : "${newValue.toInt()} điểm";

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Xác nhận thay đổi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mã ${order.productCode} sẽ được sửa như sau:"),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      oldDisplay,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                  Flexible(
                    child: Text(
                      newDisplay,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Thao tác này sẽ thay đổi số tiền đã ghi nhận của khách hàng và "
              "không thể hoàn tác. Vui lòng kiểm tra kỹ trước khi xác nhận.",
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận sửa"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (isTypeA) {
      order.amount = newValue;
    } else {
      order.unit = newValue.toInt();
    }
    await order.save();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã cập nhật mã ${order.productCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = ConfigService().getConfig();
    final kw = keyword.toLowerCase().trim();

    final filteredOrders = widget.orders.where((order) {
      final matchType = selectedType == _all || order.type == selectedType;
      if (!matchType) return false;
      if (kw.isEmpty) return true;

      final customer = customerRepo.getById(order.customerId);

      return order.productCode.toLowerCase().contains(kw) ||
          (customer?.name.toLowerCase().contains(kw) ?? false) ||
          (customer?.phone.toLowerCase().contains(kw) ?? false);
    }).toList();

    double orderValue(Order o) => o.type == "A" ? o.amount : o.unit.toDouble();
    switch (sortOption) {
      case _OrderSortOption.timeDesc:
        filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _OrderSortOption.timeAsc:
        filteredOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _OrderSortOption.valueDesc:
        filteredOrders.sort((a, b) => orderValue(b).compareTo(orderValue(a)));
        break;
      case _OrderSortOption.valueAsc:
        filteredOrders.sort((a, b) => orderValue(a).compareTo(orderValue(b)));
        break;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: searchController,
            onChanged: (v) => setState(() => keyword = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: "Tìm theo tên, mã, SĐT...",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: keyword.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        setState(() => keyword = "");
                      },
                    ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _PillDropdown<String>(
                  icon: Icons.category_outlined,
                  value: selectedType,
                  accent: selectedType == "A"
                      ? Colors.indigo
                      : selectedType == "B"
                      ? Colors.teal
                      : colorScheme.primary,
                  items: const [
                    DropdownMenuItem(value: _all, child: Text("Tất cả loại")),
                    DropdownMenuItem(value: "A", child: Text("Loại A")),
                    DropdownMenuItem(value: "B", child: Text("Loại B")),
                  ],
                  onChanged: (v) => setState(() => selectedType = v ?? _all),
                ),
              ),
              const SizedBox(width: 8),
              _SortMenuButton<_OrderSortOption>(
                value: sortOption,
                values: _OrderSortOption.values,
                onChanged: (v) => setState(() => sortOption = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Không tìm thấy kết quả",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];

                    final customer = customerRepo.getById(order.customerId);
                    final isTypeA = order.type == "A";
                    final typeColor = isTypeA ? Colors.indigo : Colors.teal;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: typeColor.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                order.type,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Mã ${order.productCode}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 13,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          customer?.name ?? "Không rõ",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((customer?.phone ?? "").isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            customer!.phone,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 13,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _formatDateTime(order.createdAt),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.formatNumber(
                                      isTypeA
                                          ? order.amount
                                          : order.unit.toDouble(),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  Material(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _editOrder(context, order),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_rounded,
                                              size: 14,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Sửa",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MoneyCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MoneyCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
