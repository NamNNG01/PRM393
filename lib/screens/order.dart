import 'package:flutter/material.dart';
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
import '../models/customer.dart';
import '../models/configuration.dart';
import '../services/config_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final configBox = Hive.box<Configuration>(HiveBoxes.configBox);
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
    buffer.writeln("");

    double totalA = 0;

    for (final e in typeA.entries) {
      totalA += e.value;

      buffer.writeln("${e.key} : ${_formatNumber(e.value)}");
    }

    buffer.writeln("");
    buffer.writeln("Tổng A: ${_formatNumber(totalA)}");

    buffer.writeln("");
    buffer.writeln("LOẠI B");
    buffer.writeln("");

    int totalPointB = 0;
    double totalMoneyB = 0;

    for (final e in typeB.entries) {
      totalPointB += e.value;

      final money = e.value * config.ticketPriceB;

      totalMoneyB += money;

      buffer.writeln("${e.key} : ${e.value} điểm (${_formatNumber(money)})");
    }

    buffer.writeln("");
    buffer.writeln("Tổng B: $totalPointB điểm (${_formatNumber(totalMoneyB)})");

    buffer.writeln("");
    buffer.writeln("══════════════");

    buffer.writeln("TỔNG DOANH THU: ${_formatNumber(totalA + totalMoneyB)}");

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
                      _AppBarIconButton(
                        tooltip: "Quay lại",
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Đơn hàng",
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
                              DateUtil.today(),
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
                      IconButton(
                        tooltip: "Chọn ngày",
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 22,
                        ),
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
                      const SizedBox(width: 4),

                      PopupMenuButton<String>(
                        tooltip: "Báo cáo & bồi hoàn",
                        padding: const EdgeInsets.all(6),
                        icon: const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 22,
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
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: "report",
                            child: Text("📊 Báo cáo tài chính"),
                          ),
                          PopupMenuItem(
                            value: "settlement",
                            child: Text("💰 Tính bồi hoàn"),
                          ),
                        ],
                      ),

                      const SizedBox(width: 4),

                      _AppBarIconButton(
                        tooltip: "Cài đặt",
                        icon: Icons.settings_outlined,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 2),
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

              if (orderBox.isEmpty) {
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
                          "Chưa có đơn hàng nào",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bắt đầu bằng cách nhập danh sách đơn hàng loại A hoặc B",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
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
                            label: const Text("Nhập đơn hàng"),
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

              for (final o in orders) {
                final revenueValue = o.type == "A"
                    ? o.amount
                    : o.unit * config.ticketPriceB;

                totalRevenue += revenueValue;

                final groupKey = "${o.type}|${o.productCode}";

                grouped[groupKey] = (grouped[groupKey] ?? 0) + revenueValue;

                if (o.type == "A") {
                  totalAmountA += o.amount;
                  totalCommission += o.amount * config.commissionRateA;
                } else {
                  totalAmountB += o.unit * config.ticketPriceB;
                  totalCommission += o.unit * config.commissionPerPointB;
                }
              }
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
                            label: "Tổng đơn hàng",
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
                        "Import",
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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  _copyOrders();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Copy",
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

class _OverviewTabState extends State<_OverviewTab> {
  static const String _all = "__all__";
  String selectedCode = _all;

  @override
  Widget build(BuildContext context) {
    final codes = widget.grouped.keys.toList()..sort();

    final filteredEntries = widget.grouped.entries
        .where((e) => selectedCode == _all || e.key == selectedCode)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _MoneyCard(
                title: "Tổng doanh thu",
                value: widget.formatNumber(widget.totalRevenue),
              ),

              _MoneyCard(
                title: "Hoa hồng",
                value: widget.formatNumber(widget.commission),
              ),

              _MoneyCard(
                title: "Thực chuyển cấp trên",
                value: widget.formatNumber(widget.transferToUpper),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            initialValue: selectedCode,
            decoration: InputDecoration(
              isDense: true,
              labelText: "Lọc theo mã sản phẩm",
              prefixIcon: const Icon(Icons.filter_alt_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem(value: _all, child: Text("Tất cả")),
              ...codes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) => setState(() => selectedCode = v ?? _all),
          ),
        ),

        const Divider(),

        if (filteredEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text("Không tìm thấy mã sản phẩm")),
          )
        else
          ...filteredEntries.map((e) {
            final parts = e.key.split('|');

            final type = parts[0];
            final code = parts[1];

            return ListTile(
              title: Text(
                code,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Loại $type"),
              trailing: Text(widget.formatNumber(e.value)),
            );
          }),
      ],
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
  String selectedCustomerId = _all;
  String selectedCode = _all;

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    return "${_two(dt.day)}/${_two(dt.month)}/${dt.year} "
        "${_two(dt.hour)}:${_two(dt.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final config = ConfigService().getConfig();
    final codes = widget.orders.map((o) => o.productCode).toSet().toList()
      ..sort();

    final customerIds = widget.orders.map((o) => o.customerId).toSet();
    final customers =
        customerIds
            .map((id) => customerRepo.getById(id))
            .whereType<Customer>()
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final filteredOrders = widget.orders.where((order) {
      final matchCustomer =
          selectedCustomerId == _all || order.customerId == selectedCustomerId;
      final matchCode =
          selectedCode == _all || order.productCode == selectedCode;
      return matchCustomer && matchCode;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: DropdownButtonFormField<String>(
            initialValue: selectedCustomerId,
            decoration: InputDecoration(
              isDense: true,
              labelText: "Lọc theo khách hàng",
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem(value: _all, child: Text("Tất cả")),
              ...customers.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    "${c.name} - ${c.phone}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => selectedCustomerId = v ?? _all),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            initialValue: selectedCode,
            decoration: InputDecoration(
              isDense: true,
              labelText: "Lọc theo mã sản phẩm",
              prefixIcon: const Icon(Icons.filter_alt_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem(value: _all, child: Text("Tất cả")),
              ...codes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) => setState(() => selectedCode = v ?? _all),
          ),
        ),
        Expanded(
          child: filteredOrders.isEmpty
              ? const Center(child: Text("Không tìm thấy kết quả"))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];

                    final customer = customerRepo.getById(order.customerId);

                    final value = order.type == "A"
                        ? order.amount
                        : order.unit * config.ticketPriceB;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(order.productCode),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${customer?.name ?? "Không rõ"}"
                              " - "
                              "${customer?.phone ?? ""}",
                            ),

                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 13,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(order.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              order.type == "A"
                                  ? widget.formatNumber(order.amount)
                                  : "${order.unit} điểm",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            if (order.type == "B")
                              Text(
                                widget.formatNumber(
                                  order.unit * config.ticketPriceB,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
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

  const _MoneyCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
