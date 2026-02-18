class AgeUtils {
  static String formatAge(String? birthDateStr) {
    if (birthDateStr == null || birthDateStr.isEmpty) return '-';

    try {
      final birthDate = DateTime.parse(birthDateStr);
      final now = DateTime.now();

      int years = now.year - birthDate.year;
      int months = now.month - birthDate.month;
      int days = now.day - birthDate.day;

      if (days < 0) {
        months -= 1;
        final prevMonth = DateTime(now.year, now.month, 0);
        days += prevMonth.day;
      }

      if (months < 0) {
        years -= 1;
        months += 12;
      }

      return '( $years Tahun $months Bulan $days Hari )';
    } catch (e) {
      return '-';
    }
  }
}
