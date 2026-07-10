class DateUtil {
  static DateTime selectedDate = DateTime.now();

  static String today() {
    final now = selectedDate;

    return "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }
}
