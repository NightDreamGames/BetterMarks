import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintf/sprintf.dart';
import 'package:diacritic/diacritic.dart';

import 'subject.dart';
import 'test.dart';

class Calculator {
  static void sort1(List<Subject> data, String sortMode) {
    if (data.length >= 2) {
      switch (Settings.getValue<int>(sortMode, 0)) {
        case 0:
          data.sort((o1, o2) => removeDiacritics(o1.name.toLowerCase())
              .replaceAll("[^\\p{ASCII}]", "")
              .compareTo(removeDiacritics(o2.name.toLowerCase()).replaceAll("[^\\p{ASCII}]", "")));
          break;
        case 1:
          data.sort((o1, o2) => o2.result.compareTo(o1.result));
          break;
      }
    }
  }

  static void sort2(List<Test> data) {
    if (data.length >= 2) {
      switch (Settings.getValue<int>("sort_mode2", 0)) {
        case 0:
          data.sort((o1, o2) => removeDiacritics(o1.name.toLowerCase())
              .replaceAll("[^\\p{ASCII}]", "")
              .compareTo(removeDiacritics(o2.name.toLowerCase()).replaceAll("[^\\p{ASCII}]", "")));
          break;
        case 1:
          data.sort((o1, o2) => (o2.grade1 / o2.grade2).compareTo(o1.grade1 / o1.grade2));
          break;
      }
    }
  }

  static double calculate(List<double> results, List<double> coefficients) {
    if (results.isEmpty) {
      return -1;
    }

    double a = 0;
    double b = 0;

    for (int i = 0; i < results.length; i++) {
      if (results[i] != -1) {
        a += results[i] * coefficients[i];
        b += coefficients[i];
      }
    }

    if (b > 0) {
      return round(a / b);
    } else {
      return -1;
    }
  }

  static double round(double n) {
    String roundingMode = Settings.getValue<String>("rounding_mode", "rounding_up");
    int roundTo = Settings.getValue<int>("round_to", 1);

    switch (roundingMode) {
      case "rounding_up":
        double a = n * roundTo;
        return a.ceilToDouble() / roundTo;
      case "rounding_down":
        double a = n * roundTo;
        return a.floorToDouble() / roundTo;
      case "rounding_half_up":
        double i = (n * roundTo).ceilToDouble();
        double f = n - i;
        return (f < 0.5 ? i : i + 1) / roundTo;
      case "rounding_half_down":
        double i1 = n * roundTo;
        i1 = i1.floorToDouble();
        double f1 = n - i1;
        return (f1 <= 0.5 ? i1 : i1 + 1) / roundTo;
      default:
        return n;
    }
  }

  static String format(double n) {
    String a;
    if (n == n.toInt()) {
      a = sprintf("%d", [n.toInt()]);
    } else {
      a = sprintf("%s", [n]);
    }
    if (n < 10) {
      return 0.toString() + a;
    } else {
      return a;
    }
  }
}
