import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/configuration.dart';
import '../services/config_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final configService = ConfigService();

  late Configuration config;

  @override
  void initState() {
    super.initState();
    config = configService.getConfig();
  }

  void save() {
    configService.saveConfig(config);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã lưu cấu hình")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt hệ thống")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// COMMISSION A
            _buildSlider(
              title: "Hoa hồng loại A (%)",
              value: config.commissionRateA,
              min: 0,
              max: 1,
              onChanged: (v) {
                setState(() {
                  config.commissionRateA = v;
                });
              },
            ),

            const SizedBox(height: 20),

            /// REFUND A
            _buildNumberInput(
              title: "Tỷ lệ bồi hoàn loại A",
              value: config.refundRateA,
              onChanged: (v) {
                config.refundRateA = v;
              },
            ),

            const SizedBox(height: 20),

            /// COMMISSION B
            _buildNumberInput(
              title: "Hoa hồng loại B / đơn vị",
              value: config.commissionPerPointB,
              onChanged: (v) {
                config.commissionPerPointB = v;
              },
            ),

            const SizedBox(height: 20),

            /// REFUND B
            _buildNumberInput(
              title: "Tỷ lệ bồi hoàn loại B",
              value: config.refundRateB,
              onChanged: (v) {
                config.refundRateB = v;
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: save,
                child: const Text("LƯU CẤU HÌNH"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: "${(value * 100).toStringAsFixed(0)}%",
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String title,
    required double value,
    required Function(double) onChanged,
  }) {
    final controller = TextEditingController(text: value.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            onChanged(double.tryParse(v) ?? value);
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
