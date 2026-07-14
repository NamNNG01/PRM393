import 'package:hive/hive.dart';

import '../hive/hive_boxes.dart';
import '../models/winning_result.dart';

class WinningResultRepository {
  final Box<WinningResult> _box = Hive.box<WinningResult>(
    HiveBoxes.winningResultBox,
  );

  List<WinningResult> getByDate(String businessDate) {
    return _box.values.where((e) => e.businessDate == businessDate).toList();
  }

  WinningResult? getResult(String businessDate, String ticketType) {
    try {
      return _box.values.firstWhere(
        (e) => e.businessDate == businessDate && e.ticketType == ticketType,
      );
    } catch (_) {
      return null;
    }
  }

  bool exists(String businessDate, String ticketType) {
    return _box.values.any(
      (e) => e.businessDate == businessDate && e.ticketType == ticketType,
    );
  }

  Future<void> saveResult(WinningResult result) async {
    await _box.add(result);
  }

  Future<void> deleteByDate(String businessDate) async {
    final list = _box.values
        .where((e) => e.businessDate == businessDate)
        .toList();

    for (final item in list) {
      await item.delete();
    }
  }

  Future<void> saveOrUpdate({
    required String businessDate,
    required String ticketType,
    required String winningNumbers,
  }) async {
    final existed = getResult(businessDate, ticketType);

    if (existed == null) {
      await _box.add(
        WinningResult(
          businessDate: businessDate,
          ticketType: ticketType,
          winningNumbers: winningNumbers,
        ),
      );
    } else {
      existed.winningNumbers = winningNumbers;
      await existed.save();
    }
  }

  Future<void> addNumbers({
    required String businessDate,
    required List<String> numbers,
  }) async {
    final result = getResult(businessDate, "B");

    if (result == null) {
      await saveOrUpdate(
        businessDate: businessDate,
        ticketType: "B",
        winningNumbers: numbers.join(","),
      );
      return;
    }

    final old = result.winningNumbers
        .split(",")
        .where((e) => e.isNotEmpty)
        .toSet();

    old.addAll(numbers);

    result.winningNumbers = old.join(",");

    await result.save();
  }
}
