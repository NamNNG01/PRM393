import 'package:flutter/material.dart';

import '../services/risk_engine.dart';
import '../repositories/order_repository.dart';
import '../models/order.dart';
import 'report.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RunEngineScreen extends StatelessWidget {
  const RunEngineScreen({super.key});

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text("Yêu cầu đăng nhập"),
          ],
        ),
        content: const Text(
          "Bạn cần đăng nhập để truy cập tính năng Báo cáo tài chính Premium.\n\n"
          "Đăng ký tài khoản mới từ ngày 13/07 đến 26/07/2026 để được tặng 30 ngày sử dụng Premium miễn phí!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Đăng nhập"),
          ),
        ],
      ),
    );
  }

  void _showPremiumRequiredDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text("Yêu cầu Premium"),
          ],
        ),
        content: Text(
          "Tính năng này chỉ dành cho tài khoản Premium.\n\n"
          "Trạng thái hiện tại: $reason",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToReport(BuildContext context, dynamic resultA, dynamic resultB) async {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      _showLoginRequiredDialog(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final premiumStatus = await authService.checkPremiumStatus();
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    if (premiumStatus['isPremium'] == true) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportScreen(
              resultA: resultA,
              resultB: resultB,
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        _showPremiumRequiredDialog(context, premiumStatus['reason'] ?? 'Yêu cầu tài khoản Premium');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chạy tính toán"),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text("TÍNH BÁO CÁO"),
          onPressed: () {
            final engine = RiskEngine();
            final repo = OrderRepository();

            final orders = repo.getAll();

            // tạm chia giả lập
            final Map<Order, double> dataA = {};
            final Map<Order, int> dataB = {};

            for (var o in orders) {
              if (o.type == "A") {
                dataA[o] = o.amount;
              } else {
                dataB[o] = o.unit;
              }
            }

            final resultA = engine.processTypeA(dataA);
            final resultB = engine.processTypeB(dataB);

            _navigateToReport(context, resultA, resultB);
          },
        ),
      ),
    );
  }
}