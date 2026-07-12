
class OrderParser {
  static Map<String, double> parseInput(String input) {
    final Map<String, double> result = {};

    final lines = input.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final parsed = _parseLine(line);
      if (parsed == null) continue;

      final code = parsed.code;
      final value = parsed.value;

      result[code] = (result[code] ?? 0) + value;
    }

    return result;
  }

  static _ParsedLine? _parseLine(String line) {
    final clean = line
        .replaceAll(',', ' ')
        .replaceAll(':', ' ')
        .replaceAll('*', ' ')
        .replaceAll('-', ' ')
        .replaceAll('x', ' ')
        .replaceAll('X', ' ')
        .trim();

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length < 2) return null;

    final code = parts[0];

    final value = double.tryParse(parts[1]);
    if (value == null) return null;

    return _ParsedLine(code, value);
  }
}

class _ParsedLine {
  final String code;
  final double value;

  _ParsedLine(this.code, this.value);
}
