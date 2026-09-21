class Formatters {
  Formatters._();

  static String watts(
    double value,
  ) {
    return '${value.toStringAsFixed(1)} W';
  }

  static String amps(
    double value,
  ) {
    return '${value.toStringAsFixed(2)} A';
  }

  static String volts(
    double value,
  ) {
    return '${value.toStringAsFixed(1)} V';
  }

  static String kilowattHours(
    double value,
  ) {
    return '${value.toStringAsFixed(3)} kWh';
  }

  static String mxn(
    double value,
  ) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  static String mxnPerHour(
    double value,
  ) {
    return '\$${value.toStringAsFixed(3)} MXN/h';
  }

  static String percentage(
    double value,
  ) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String integerPercentage(
    double value,
  ) {
    return '${value.round()}%';
  }

  static String date(
    DateTime dateTime,
  ) {
    final DateTime local =
        dateTime.toLocal();

    final String day =
        local.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String month =
        local.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String year =
        local.year.toString();

    return '$day/$month/$year';
  }

  static String time(
    DateTime dateTime,
  ) {
    final DateTime local =
        dateTime.toLocal();

    final String hour =
        local.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String minute =
        local.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  static String dateTime(
    DateTime dateTime,
  ) {
    return '${date(dateTime)} ${time(dateTime)}';
  }

  static String shortMonth(
    int month,
  ) {
    const List<String> months =
        <String>[
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    if (month < 1 ||
        month > 12) {
      return '';
    }

    return months[month];
  }

  static String monthYear(
    DateTime dateTime,
  ) {
    return '${shortMonth(dateTime.month)} ${dateTime.year}';
  }

  static String timerDuration(
    Duration duration,
  ) {
    final int hours =
        duration.inHours;

    final int minutes =
        duration.inMinutes
            .remainder(60);

    final int seconds =
        duration.inSeconds
            .remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String cleanDeviceName(
    String? value,
  ) {
    final String text =
        value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Dispositivo NEXUS';
    }

    return text;
  }
}