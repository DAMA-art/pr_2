import 'package:flutter_test/flutter_test.dart';
import 'package:pr_2/utils/grooming_quote.dart';

void main() {
  group('GroomingQuote.intervalsOverlap', () {
    test('пересекающиеся интервалы', () {
      final a = DateTime(2026, 1, 1, 10);
      final b = DateTime(2026, 1, 1, 11);
      final c = DateTime(2026, 1, 1, 10, 30);
      final d = DateTime(2026, 1, 1, 12);
      expect(GroomingQuote.intervalsOverlap(a, b, c, d), isTrue);
    });

    test('смежные интервалы не пересекаются', () {
      final a = DateTime(2026, 1, 1, 10);
      final b = DateTime(2026, 1, 1, 11);
      final c = DateTime(2026, 1, 1, 11);
      final d = DateTime(2026, 1, 1, 12);
      expect(GroomingQuote.intervalsOverlap(a, b, c, d), isFalse);
    });
  });

  group('GroomingQuote.calculate', () {
    test('сумма услуг без надбавок', () {
      final r = GroomingQuote.calculate(
        servicePrices: [1000, 500],
        petWeightKg: 4,
        species: 'cat',
        completedVisits: 0,
      );
      expect(r.base, 1500);
      expect(r.largeSurcharge, 0);
      expect(r.multiDiscount, 0);
      expect(r.loyalDiscount, 0);
      expect(r.total, 1500);
    });

    test('надбавка за крупного питомца', () {
      final r = GroomingQuote.calculate(
        servicePrices: [1000],
        petWeightKg: 26,
        species: 'dog',
        completedVisits: 0,
      );
      expect(r.largeSurcharge, 300);
      expect(r.total, 1300);
    });

    test('скидка за комплекс из трёх услуг', () {
      final r = GroomingQuote.calculate(
        servicePrices: [1000, 1000, 1000],
        petWeightKg: 5,
        species: 'dog',
        completedVisits: 0,
      );
      expect(r.multiDiscount, 300);
      expect(r.total, 2700);
    });

    test('скидка постоянного клиента', () {
      final r = GroomingQuote.calculate(
        servicePrices: [2000],
        petWeightKg: 5,
        species: 'cat',
        completedVisits: 5,
      );
      expect(r.loyalDiscount, 300);
      expect(r.total, 1700);
    });
  });
}
