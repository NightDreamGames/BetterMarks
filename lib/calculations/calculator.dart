// Dart imports:
import "dart:math";

// Package imports:
import "package:collection/collection.dart";

// Project imports:
import "package:graded/calculations/calculation_object.dart";
import "package:graded/calculations/manager.dart";
import "package:graded/calculations/test.dart";
import "package:graded/misc/default_values.dart";
import "package:graded/misc/enums.dart";
import "package:graded/misc/storage.dart";

class Calculator {
  static void sortObjects(
    List<CalculationObject> data, {
    required int sortType,
    int? sortModeOverride,
    int? sortDirectionOverride,
    List<CalculationObject>? comparisonData,
  }) {
    if (data.length < 2) return;

    final int sortDirection = sortDirectionOverride ?? getPreference<int>("sort_direction$sortType");
    int sortMode = getPreference<int>("sort_mode$sortType");
    if (sortModeOverride != null && sortMode != SortMode.custom) {
      sortMode = sortModeOverride;
    }

    switch (sortMode) {
      case SortMode.name:
        insertionSort(
          data,
          compare: (a, b) {
            int result = compareNatural(a.asciiName, b.asciiName);
            if (result == 0) {
              result = compareNatural(a.name, b.name);
            }
            return sortDirection * result;
          },
        );
      case SortMode.result:
        insertionSort(
          data,
          compare: (a, b) {
            if (a.result == null && b.result == null) {
              return 0;
            } else if (b.result == null) {
              return -1;
            } else if (a.result == null) {
              return 1;
            }

            return sortDirection * a.result!.compareTo(b.result!);
          },
        );
      case SortMode.coefficient:
        insertionSort(data, compare: (a, b) => sortDirection * a.weight.compareTo(b.weight));
      case SortMode.custom:
        final compare = comparisonData ?? getCurrentYear().termTemplate;
        data.sort((a, b) {
          return compare.indexWhere((element) => a.name == element.name) - compare.indexWhere((element) => b.name == element.name);
        });
      case SortMode.timestamp:
        if (data.first is! Test) throw UnimplementedError("Timestamp sorting is only implemented for tests");

        insertionSort(
          data,
          compare: (a, b) {
            int result = (a as Test).timestamp.compareTo((b as Test).timestamp);
            if (result == 0) {
              result = a.asciiName.compareTo(b.asciiName);
            }
            return result * sortDirection;
          },
        );
    }
  }

  static double? calculate(Iterable<CalculationObject> data, {double bonus = 0, bool precise = false, double speakingWeight = 1}) {
    final bool isNullFilled = data.every((element) => element.numerator == null || element.denominator == 0);

    if (data.isEmpty || isNullFilled) return null;

    final double maxGrade = Manager.years.isNotEmpty ? getCurrentYear().maxGrade : getPreference("max_grade");

    double totalNumerator = 0;
    double totalDenominator = 0;
    double totalNumeratorSpeaking = 0;
    double totalDenominatorSpeaking = 0;

    for (final CalculationObject c in data.where((element) => element.numerator != null && element.denominator != 0)) {
      if (c is Test && c.isSpeaking) {
        totalNumeratorSpeaking += c.numerator! * c.weight;
        totalDenominatorSpeaking += c.denominator * c.weight;
      } else {
        totalNumerator += c.numerator! * c.weight;
        totalDenominator += c.denominator * c.weight;
      }
    }

    double result = totalNumerator * (maxGrade / totalDenominator);
    double resultSpeaking = totalNumeratorSpeaking * (maxGrade / totalDenominatorSpeaking);
    if (result.isNaN) result = resultSpeaking;
    if (resultSpeaking.isNaN) resultSpeaking = result;

    final double totalResult = (result * speakingWeight + resultSpeaking) / (speakingWeight + 1) + bonus;

    return round(totalResult, roundToMultiplier: precise ? DefaultValues.preciseRoundToMultiplier : 1);
  }

  static double round(double n, {String? roundingModeOverride, int? roundToOverride, int roundToMultiplier = 1}) {
    final String roundingMode = roundingModeOverride ?? (Manager.years.isNotEmpty ? getCurrentYear().roundingMode : getPreference("rounding_mode"));
    int roundTo = roundToOverride ?? (Manager.years.isNotEmpty ? getCurrentYear().roundTo : getPreference<int>("round_to"));
    roundTo *= roundToMultiplier;

    final double round = n * roundTo;

    switch (roundingMode) {
      case RoundingMode.up:
        return round.ceilToDouble() / roundTo;
      case RoundingMode.down:
        return round.floorToDouble() / roundTo;
      case RoundingMode.halfUp:
        return round.roundToDouble() / roundTo;
      case RoundingMode.halfDown:
        final double base = round.truncateToDouble();
        final double decimals = n - base;
        final int sign = n < 0 ? -1 : 1;

        return (decimals <= 0.5 ? base : base + 1 * sign) / roundTo;
      default:
        return n;
    }
  }

  static double? tryParse(String? input) {
    if (input == null) return null;
    return double.tryParse(input.replaceAll(",", ".").replaceAll(" ", ""));
  }

  static String format(double? n, {bool leadingZero = true, int? roundToOverride, int roundToMultiplier = 1, bool showPlusSign = false}) {
    if (n == null || n.isNaN) return "-";

    int roundTo = roundToOverride ?? (Manager.years.isNotEmpty ? getCurrentYear().roundTo : getPreference<int>("round_to"));
    roundTo *= roundToMultiplier;

    String result;

    int nbDecimals = (log(roundTo) / log(10)).round();
    if (n % 1 != 0) {
      nbDecimals = max(n.toString().split(".")[1].length, nbDecimals);
    }

    result = n.toStringAsFixed(nbDecimals);

    if (leadingZero && getPreference<bool>("leading_zero") && n >= 1 && n < 10) {
      result = "0$result";
    }
    if (showPlusSign && n >= 0) {
      result = "+$result";
    }

    return result;
  }
}
