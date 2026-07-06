import 'package:hive/hive.dart';

import '../hive/hive_boxes.dart';
import '../models/configuration.dart';

class ConfigRepository {
  final Box<Configuration> _box =
      Hive.box<Configuration>(HiveBoxes.configBox);

  Configuration? getConfig() {
    if (_box.isEmpty) return null;
    return _box.getAt(0);
  }

  Future<void> saveConfig(Configuration config) async {
    if (_box.isEmpty) {
      await _box.add(config);
    } else {
      await _box.putAt(0, config);
    }
  }
}