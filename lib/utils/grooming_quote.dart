class GroomingQuoteResult {
  final double base;
  final double largeSurcharge;
  final double multiDiscount;
  final double loyalDiscount;
  final double total;

  const GroomingQuoteResult({
    required this.base,
    required this.largeSurcharge,
    required this.multiDiscount,
    required this.loyalDiscount,
    required this.total,
  });
}

class GroomingQuote {
  static const double largeWeightKg = 25;
  static const double largeSurchargeRate = 0.30;
  static const double multiServiceRate = 0.10;
  static const int multiServiceFrom = 3;
  static const double loyalRate = 0.15;
  static const int loyalFromVisits = 5;

  static bool intervalsOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  static GroomingQuoteResult calculate({
    required List<double> servicePrices,
    required double petWeightKg,
    required String species,
    required int completedVisits,
  }) {
    final base = servicePrices.fold<double>(0, (sum, p) => sum + p);
    final large = petWeightKg >= largeWeightKg || species == 'horse';
    final surcharge = large ? base * largeSurchargeRate : 0.0;
    final afterSurcharge = base + surcharge;
    final multi = servicePrices.length >= multiServiceFrom
        ? afterSurcharge * multiServiceRate
        : 0.0;
    final afterMulti = afterSurcharge - multi;
    final loyal = completedVisits >= loyalFromVisits
        ? afterMulti * loyalRate
        : 0.0;
    final total = (afterMulti - loyal).clamp(0, double.infinity).toDouble();
    return GroomingQuoteResult(
      base: base,
      largeSurcharge: surcharge,
      multiDiscount: multi,
      loyalDiscount: loyal,
      total: total,
    );
  }
}
