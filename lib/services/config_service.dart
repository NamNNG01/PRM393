import 'package:hive/hive.dart';
import '../models/configuration.dart';

class ConfigService {
  static const String boxName = "config_box";
  static const String key = "config";

  Box get _box => Hive.box(boxName);

  Configuration getConfig() {
    final config = _box.get(
      key,
      defaultValue: Configuration.defaultConfig(),
    );

    return config;
  }

  void saveConfig(Configuration config) {
    _box.put(key, config);
  }
}