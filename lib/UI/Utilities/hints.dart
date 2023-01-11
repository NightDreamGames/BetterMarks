// Project imports:
import '../../Calculations/manager.dart';
import '../../Calculations/subject.dart';
import '../../Calculations/test.dart';
import '../../Misc/storage.dart';
import '../../Translations/translations.dart';

String getSubjectHint() {
  bool a = false;
  String defaultName = "Subject 1";
  int i = 1;

  do {
    defaultName = "${Translations.subject} ${Manager.termTemplate.length + i}";

    for (Subject t in Manager.termTemplate) {
      if (t.name == defaultName) {
        a = true;
        i++;
        break;
      } else {
        a = false;
      }
    }
  } while (a);

  return defaultName;
}

String getTestHint(Subject subject) {
  bool a = false;
  String defaultName = "";
  int i = 1;

  do {
    defaultName = "${Translations.test} ${subject.tests.length + i}";

    for (Test t in subject.tests) {
      if (t.name == defaultName) {
        a = true;
        i++;
        break;
      } else {
        a = false;
      }
    }
  } while (a);

  return defaultName;
}

String getTitle({int? termOverride}) {
  int currentTerm = termOverride ?? Manager.currentTerm;
  if (currentTerm == -1) return Translations.year_overview;

  switch (Storage.getPreference<int>("term")) {
    case 3:
      return "${Translations.trimester} ${currentTerm + 1}";
    case 2:
      return "${Translations.semester} ${currentTerm + 1}";
    case 1:
      return Translations.year;
  }

  return Translations.app_name;
}
