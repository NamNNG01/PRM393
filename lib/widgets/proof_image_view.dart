import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProofImageView extends StatelessWidget {
  final String path;

  const ProofImageView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return const SizedBox();
    }

    // WEB
    if (kIsWeb) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text(
          "Ảnh được upload từ thiết bị\n(Web không đọc được đường dẫn local)",
          textAlign: TextAlign.center,
        ),
      );
    }

    final file = File(path);

    if (!file.existsSync()) {
      return const Text("Không tìm thấy file");
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(file, height: 220, fit: BoxFit.cover),
    );
  }
}
