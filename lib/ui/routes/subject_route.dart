// Dart imports:
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../calculations/calculator.dart';
import '../../calculations/manager.dart';
import '../../calculations/subject.dart';
import '../../calculations/term.dart';
import '../../localization/translations.dart';
import '../../misc/storage.dart';
import '../utilities/misc_utilities.dart';
import '../widgets/dialogs.dart';
import '../widgets/list_widgets.dart';
import '../widgets/misc_widgets.dart';
import '../widgets/popup_menus.dart';

class SubjectRoute extends StatefulWidget {
  const SubjectRoute({Key? key}) : super(key: key);

  @override
  State<SubjectRoute> createState() => _SubjectRouteState();
}

class _SubjectRouteState extends State<SubjectRoute> {
  late int index1 = -1;
  late int index2 = -1;
  late Term term = Manager.getCurrentTerm();
  late Subject subject = index2 == -1 ? term.subjects[index1] : term.subjects[index1].children[index2];
  late Subject? parent = index2 != -1 ? term.subjects[index1] : null;
  bool resultTapped = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController maximumController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    gradeController.dispose();
    maximumController.dispose();
    super.dispose();
  }

  void rebuild() {
    if (getPreference<int>("sort_mode${SortType.subject}") != SortMode.result) {
      subject = index2 == -1 ? term.subjects[index1] : term.subjects[index1].children[index2];
      parent = index2 != -1 ? term.subjects[index1] : null;
    } else {
      index1 = term.subjects.indexOf(parent ?? subject);
      index2 = term.subjects[index1].children.indexOf(subject);
    }

    setState(() {});
  }

  void switchTerm() {
    term = Manager.getCurrentTerm();
    index1 = term.subjects.indexWhere((element) {
      if (element.processedName == subject.processedName) {
        return true;
      }
      if (element.isGroup) {
        return element.children.indexWhere((element) => element.processedName == subject.processedName) != -1;
      }
      return false;
    });
    index2 = term.subjects[index1].children.indexWhere((element) {
      return element.processedName == subject.processedName;
    });
    subject = index2 == -1 ? term.subjects[index1] : term.subjects[index1].children[index2];
    parent = index2 != -1 ? term.subjects[index1] : null;

    rebuild();
  }

  @override
  Widget build(BuildContext context) {
    if (index1 == -1) {
      List<int?> arguments = ModalRoute.of(context)?.settings.arguments as List<int?>;
      index1 = arguments[0] ?? 0;
      index2 = arguments[1] ?? -1;
    }

    return Scaffold(
      floatingActionButton: Manager.currentTerm != -1
          ? FloatingActionButton(
              onPressed: () => {showTestDialog(context, subject, nameController, gradeController, maximumController).then((_) => rebuild())},
              child: const Icon(Icons.add),
            )
          : null,
      body: CustomScrollView(
        primary: true,
        slivers: [
          SliverAppBar.large(
            title: AppBarTitle(
              title: subject.name,
              actionAmount: 2,
            ),
            actions: [
              TermSelector(rebuild: switchTerm),
              SortSelector(rebuild: rebuild, type: SortType.test),
            ],
          ),
          SliverSafeArea(
            top: false,
            bottom: false,
            sliver: ResultRow(
              result: subject.getResult(precise: resultTapped),
              onResultTap: () {
                resultTapped = !resultTapped;
                rebuild();
              },
              leading: () {
                if (Manager.currentTerm != -1) {
                  return Row(
                    children: [
                      SizedBox(
                        width: (Platform.isAndroid ? 100 : 110) * MediaQuery.textScaleFactorOf(context),
                        child: Text(
                          "${translations.bonus} ${subject.bonus}${subject.bonus < 0 ? "" : "  "}",
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(left: 8)),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: () {
                          subject.changeBonus(-1);
                          rebuild();
                        },
                        style: getIconButtonStyle(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () {
                          subject.changeBonus(1);
                          rebuild();
                        },
                        style: getIconButtonStyle(context),
                      ),
                    ],
                  );
                } else {
                  return Text(
                    translations.yearly_average,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              }(),
            ),
          ),
          SliverSafeArea(
            top: false,
            bottom: false,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                addAutomaticKeepAlives: true,
                childCount: subject.tests.length,
                (context, index) {
                  GlobalKey listKey = GlobalKey();
                  return TextRow(
                    listKey: listKey,
                    leading: subject.tests[index].name,
                    trailing: subject.tests[index].toString(),
                    onTap: () async {
                      if (Manager.currentTerm != -1) {
                        showListMenu(context, listKey).then((result) {
                          if (result == MenuAction.edit) {
                            showTestDialog(context, subject, nameController, gradeController, maximumController, index: index).then((_) => rebuild());
                          } else if (result == MenuAction.delete) {
                            subject.removeTest(index);
                            rebuild();
                          }
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      ),
    );
  }
}