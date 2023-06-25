// Dart imports:
import "dart:async";
import "dart:developer";
import "dart:io";

// Flutter imports:
import "package:flutter/foundation.dart";

// Package imports:
import "package:path_provider/path_provider.dart";
import "package:xml/xml.dart";

// Project imports:
import "package:graded/calculations/manager.dart";
import "package:graded/calculations/term.dart";
import "package:graded/calculations/year.dart";
import "package:graded/misc/default_values.dart";
import "package:graded/misc/enums.dart";
import "package:graded/misc/setup_manager.dart";
import "package:graded/misc/storage.dart";

class Compatibility {
  static const dataVersion = 11;

  static Future<void> importFromV1() async {
    Uri uri;

    if (kDebugMode) {
      uri = Uri.file("${(await getApplicationDocumentsDirectory()).parent.path}/shared_prefs/com.NightDreamGames.Grade.ly.debug_preferences.xml");
    } else {
      uri = Uri.file("${(await getApplicationDocumentsDirectory()).parent.path}/shared_prefs/com.NightDreamGames.Grade.ly_preferences.xml");
    }

    if (!await File.fromUri(uri).exists()) return;

    File file = File.fromUri(uri);
    XmlDocument xml = XmlDocument.parse(file.readAsStringSync());

    List<String> keys = <String>[];
    List<String> values = <String>[];

    xml.findAllElements("string").map((e) => e.getAttribute("name")!).forEach(keys.add);
    xml.findAllElements("string").map((e) => e.innerText).forEach(values.add);

    Map<String, String> elements = {for (int i = 0; i < keys.length; i++) keys[i]: values[i]};

    setPreference<String?>("data", elements["data"]);
    setPreference<String?>("default_data", elements["default_data"]);
    setPreference<int?>("data_version", int.tryParse(elements["data_version"] ?? "-1"));
    setPreference<String?>("rounding_mode", elements["rounding_mode"]);

    String theme = "system";
    switch (elements["dark_theme"]) {
      case "on":
        theme = "dark";
      case "off":
        theme = "light";
    }
    setPreference<String?>("theme", theme);

    setPreference<String?>("school_system", elements["school_system"]);

    setPreference<int?>("round_to", int.tryParse(elements["round_to"] ?? defaultValues["round_to"].toString()));

    double totalGrades = double.parse(elements["total_grades"] ?? defaultValues["total_grades"].toString());
    if (totalGrades == -1) {
      totalGrades = double.parse(elements["custom_grade"] ?? defaultValues["total_grades"].toString());
    }
    setPreference<double>("total_grades", totalGrades);

    setPreference<bool>("is_first_run", elements["isFirstRun"]?.toLowerCase() == "true");

    if (existsPreference("period")) {
      elements.update("term", (value) => elements["period"]?.replaceFirst("period", "term") ?? defaultValues["term"] as String);
    }
    switch (elements["term"]) {
      case "term_trimester":
        setPreference<int>("term", 3);
      case "term_semester":
        setPreference<int>("term", 2);
      case "term_year":
        setPreference<int>("term", 1);
      default:
        setPreference<int>("term", defaultValues["term"] as int);
        break;
    }

    setPreference<int?>("sort_mode1", int.tryParse(elements["sort_mode"] ?? defaultValues["sort_mode1"].toString()));
    setPreference<int?>("sort_mode1", int.tryParse(elements["sort_mode1"] ?? defaultValues["sort_mode1"].toString()));
    setPreference<int?>("sort_mode2", int.tryParse(elements["sort_mode2"] ?? defaultValues["sort_mode2"].toString()));
    setPreference<int?>("sort_mode3", int.tryParse(elements["sort_mode3"] ?? defaultValues["sort_mode3"].toString()));
    setPreference<int?>("current_term", int.tryParse(elements["current_period"] ?? defaultValues["current_term"].toString()));
    setPreference<int?>("current_term", int.tryParse(elements["current_term"] ?? defaultValues["current_term"].toString()));

    file.delete();
  }

  static Future<void> upgradeDataVersion() async {
    int currentDataVersion = getPreference<int>("data_version");

    if (getPreference<bool>("is_first_run") && currentDataVersion == -1) {
      try {
        await importFromV1();
      } catch (e) {
        log("Error while importing old data: $e");
      }
    }

    if (currentDataVersion < 2) {
      setPreference<String?>("data", getPreference<String>("data").replaceAll("period", "term").replaceAll("mark", "grade"));
      setPreference<String?>("default_data", getPreference<String>("default_data").replaceAll("period", "term").replaceAll("mark", "grade"));
    }

    deserialize();

    if (currentDataVersion < 5) {
      termCount();

      setPreference<String>("language", defaultValues["language"] as String);
    }

    if (currentDataVersion < 6) {
      String variant = getPreference<String>("variant");
      String newVariant = "";
      if (variant == "latin") {
        newVariant = "L";
      } else if (variant == "chinese") {
        newVariant = "ZH";
      }
      setPreference<String>("variant", newVariant);

      String year = getPreference<String>("year", "");
      setPreference<int>("year", year.isNotEmpty ? int.parse(year.substring(0, 1)) : -1);

      setPreference<String>("validated_school_system", getPreference<String>("school_system"));
      setPreference<String>("validated_lux_system", getPreference<String>("lux_system"));
      setPreference<int>("validated_year", getPreference<int>("year"));
      setPreference<String>("validated_section", getPreference<String>("section"));
      setPreference<String>("validated_variant", getPreference<String>("variant"));
    }

    if (currentDataVersion < 7) {
      termCount();
    }

    if (currentDataVersion < 8) {
      if (getPreference<String>("validated_school_system") == "lux") {
        try {
          if (!SetupManager.hasSections(getPreference<String>("validated_lux_system"), getPreference<int>("validated_year"))) {
            setPreference<String>("validated_section", defaultValues["validated_section"] as String);
          }
        } catch (e) {
          setPreference<String>("validated_section", defaultValues["validated_section"] as String);
        }
        try {
          if (!SetupManager.hasVariants(
                getPreference<String>("validated_lux_system"),
                getPreference<int>("validated_year"),
                getPreference<String>("validated_section"),
              ) ||
              SetupManager.getVariants()[getPreference<String>("validated_variant")] == null) {
            setPreference<String>("validated_variant", defaultValues["validated_variant"] as String);
          }
        } catch (e) {
          setPreference<String>("validated_variant", defaultValues["validated_variant"] as String);
        }
      } else {
        List<String> keys = ["validated_lux_system", "validated_year", "validated_section", "validated_variant"];

        for (final String key in keys) {
          setPreference(key, defaultValues[key]);
        }
      }
    }

    if (currentDataVersion < 9) {
      //Sort direction
      for (var sortType = 1; sortType <= 2; sortType++) {
        int sortMode = getPreference<int>("sort_mode$sortType");
        int sortDirection = SortDirection.notApplicable;

        switch (sortMode) {
          case SortMode.name:
            sortDirection = SortDirection.ascending;
          case SortMode.result:
          case SortMode.coefficient:
            sortDirection = SortDirection.descending;
          case SortMode.custom:
            sortDirection = SortDirection.notApplicable;
        }
        setPreference<int>("sort_direction$sortType", sortDirection);
      }
    }

    if (currentDataVersion < 10) {
      //Fix exam coefficient
      if (getPreference<String>("validated_school_system") == "lux" && getPreference<int>("validated_year") == 1) {
        Iterable<Term> examTerms = Manager.getCurrentYear().terms.where((element) => element.coefficient == 2);

        for (final examTerm in examTerms) {
          examTerm.isExam = true;
        }
      }
    }

    if (currentDataVersion < 11) {
      //Change currentTerm behavior
      int currentTerm = getPreference<int>("current_term");
      if (currentTerm == -1) {
        setPreference("current_term", 0);
      }
    }

    setPreference<int>("data_version", dataVersion);
  }

  static void termCount() {
    int termCount = getPreference<int>("term");
    bool hasExam = getPreference<int>("validated_year") == 1;
    Manager.currentTerm = 0;

    for (final Year year in Manager.years) {
      List<Term> terms = year.terms;
      bool examPresent = terms.isNotEmpty && terms.last.coefficient == 2;

      while (terms.length > termCount + (hasExam ? 1 : 0)) {
        int index = terms.length - 1 - (hasExam ? 1 : 0);
        terms.removeAt(index);
      }

      while (terms.length < termCount + (examPresent ? 1 : 0)) {
        int index = terms.length - (examPresent ? 1 : 0);
        if (hasExam && !examPresent && terms.length > index) {
          index++;
        }
        terms.insert(index, Term());
      }

      if (hasExam && !examPresent && terms.length < termCount + 1) {
        terms.add(Term(isExam: true));
      }
    }

    serialize();
  }
}
