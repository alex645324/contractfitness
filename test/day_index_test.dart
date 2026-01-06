import 'package:flutter_test/flutter_test.dart';
import 'package:contractfitness/logic/setup_logic.dart';

void main() {
  group('getDayIndex', () {
    test('returns 0 when createdAt is null', () {
      expect(getDayIndex(null), 0);
    });

    test('returns 0 when contract created today', () {
      final today = DateTime.now();
      expect(getDayIndex(today), 0);
    });

    test('returns 4 when contract created 4 days ago', () {
      final fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));
      expect(getDayIndex(fourDaysAgo), 4);
    });

    test('returns 35 when contract created 35 days ago', () {
      final thirtyFiveDaysAgo = DateTime.now().subtract(const Duration(days: 35));
      expect(getDayIndex(thirtyFiveDaysAgo), 35);
    });

    test('returns 95 when contract created 95 days ago (beyond 90-day contract)', () {
      final ninetyFiveDaysAgo = DateTime.now().subtract(const Duration(days: 95));
      expect(getDayIndex(ninetyFiveDaysAgo), 95);
    });
  });

  group('contract boundary behavior', () {
    // UI clamps dayIndex to duration - 1 and shows COMPLETED when exceeded

    test('dayIndex clamped to duration - 1 for 90-day contract', () {
      const duration = 90;
      final rawDayIndex = 95;
      final clampedDayIndex = rawDayIndex.clamp(0, duration - 1);
      expect(clampedDayIndex, 89);
    });

    test('dayIndex clamped to duration - 1 for 60-day contract', () {
      const duration = 60;
      final rawDayIndex = 65;
      final clampedDayIndex = rawDayIndex.clamp(0, duration - 1);
      expect(clampedDayIndex, 59);
    });

    test('isContractEnded is true when dayIndex >= duration', () {
      const duration = 90;
      final rawDayIndex = 95;
      final isContractEnded = rawDayIndex >= duration;
      expect(isContractEnded, true);
    });

    test('isContractEnded is false when dayIndex < duration', () {
      const duration = 90;
      final rawDayIndex = 45;
      final isContractEnded = rawDayIndex >= duration;
      expect(isContractEnded, false);
    });
  });

  group('getDateForDayIndex', () {
    test('returns correct date string for day 0', () {
      final createdAt = DateTime(2026, 1, 1);
      expect(getDateForDayIndex(createdAt, 0), '2026-01-01');
    });

    test('returns correct date string for day 4', () {
      final createdAt = DateTime(2026, 1, 1);
      expect(getDateForDayIndex(createdAt, 4), '2026-01-05');
    });

    test('returns correct date string crossing month boundary', () {
      final createdAt = DateTime(2026, 1, 30);
      expect(getDateForDayIndex(createdAt, 3), '2026-02-02');
    });
  });
}
