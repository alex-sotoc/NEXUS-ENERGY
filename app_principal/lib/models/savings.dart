class SavingsSummary {
  const SavingsSummary({
    required this.totalSavingsMxn,
    required this.currentMonthCostMxn,
    required this.previousMonthCostMxn,
    required this.currentMonthKwh,
    required this.previousMonthKwh,
    required this.savedKwh,
    required this.percentageChange,
    required this.vampireConsumptionMxn,
    required this.vampireConsumptionKwh,
  });

  final double totalSavingsMxn;

  final double currentMonthCostMxn;

  final double previousMonthCostMxn;

  final double currentMonthKwh;

  final double previousMonthKwh;

  final double savedKwh;

  final double percentageChange;

  final double vampireConsumptionMxn;

  final double vampireConsumptionKwh;

  // ============================================================
  // ESTADOS DERIVADOS
  // ============================================================

  bool get hasSavings {
    return totalSavingsMxn > 0;
  }

  bool get improvedConsumption {
    return currentMonthKwh <
        previousMonthKwh;
  }

  bool get hasVampireConsumption {
    return vampireConsumptionKwh >
            0 ||
        vampireConsumptionMxn >
            0;
  }

  // ============================================================
  // EMPTY
  // ============================================================

  factory SavingsSummary.empty() {
    return const SavingsSummary(
      totalSavingsMxn: 0.0,
      currentMonthCostMxn: 0.0,
      previousMonthCostMxn: 0.0,
      currentMonthKwh: 0.0,
      previousMonthKwh: 0.0,
      savedKwh: 0.0,
      percentageChange: 0.0,
      vampireConsumptionMxn: 0.0,
      vampireConsumptionKwh: 0.0,
    );
  }

  // ============================================================
  // FROM JSON
  //
  // Queda preparado por si posteriormente FastAPI implementa
  // /api/savings o un resumen equivalente.
  // ============================================================

  factory SavingsSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return SavingsSummary(
      totalSavingsMxn:
          _toDouble(
        json['total_savings_mxn'],
      ),

      currentMonthCostMxn:
          _toDouble(
        json[
            'current_month_cost_mxn'],
      ),

      previousMonthCostMxn:
          _toDouble(
        json[
            'previous_month_cost_mxn'],
      ),

      currentMonthKwh:
          _toDouble(
        json['current_month_kwh'],
      ),

      previousMonthKwh:
          _toDouble(
        json['previous_month_kwh'],
      ),

      savedKwh:
          _toDouble(
        json['saved_kwh'],
      ),

      percentageChange:
          _toDouble(
        json['percentage_change'],
      ),

      vampireConsumptionMxn:
          _toDouble(
        json[
            'vampire_consumption_mxn'],
      ),

      vampireConsumptionKwh:
          _toDouble(
        json[
            'vampire_consumption_kwh'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total_savings_mxn':
          totalSavingsMxn,
      'current_month_cost_mxn':
          currentMonthCostMxn,
      'previous_month_cost_mxn':
          previousMonthCostMxn,
      'current_month_kwh':
          currentMonthKwh,
      'previous_month_kwh':
          previousMonthKwh,
      'saved_kwh':
          savedKwh,
      'percentage_change':
          percentageChange,
      'vampire_consumption_mxn':
          vampireConsumptionMxn,
      'vampire_consumption_kwh':
          vampireConsumptionKwh,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  SavingsSummary copyWith({
    double? totalSavingsMxn,
    double? currentMonthCostMxn,
    double? previousMonthCostMxn,
    double? currentMonthKwh,
    double? previousMonthKwh,
    double? savedKwh,
    double? percentageChange,
    double? vampireConsumptionMxn,
    double? vampireConsumptionKwh,
  }) {
    return SavingsSummary(
      totalSavingsMxn:
          totalSavingsMxn ??
              this.totalSavingsMxn,

      currentMonthCostMxn:
          currentMonthCostMxn ??
              this.currentMonthCostMxn,

      previousMonthCostMxn:
          previousMonthCostMxn ??
              this.previousMonthCostMxn,

      currentMonthKwh:
          currentMonthKwh ??
              this.currentMonthKwh,

      previousMonthKwh:
          previousMonthKwh ??
              this.previousMonthKwh,

      savedKwh:
          savedKwh ??
              this.savedKwh,

      percentageChange:
          percentageChange ??
              this.percentageChange,

      vampireConsumptionMxn:
          vampireConsumptionMxn ??
              this
                  .vampireConsumptionMxn,

      vampireConsumptionKwh:
          vampireConsumptionKwh ??
              this
                  .vampireConsumptionKwh,
    );
  }

  // ============================================================
  // HELPER
  // ============================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}