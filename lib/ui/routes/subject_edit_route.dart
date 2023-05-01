// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:showcaseview/showcaseview.dart';

// Project imports:
import '../../calculations/calculator.dart';
import '../../calculations/manager.dart';
import '../../calculations/subject.dart';
import '../../localization/translations.dart';
import '../../misc/storage.dart';
import '../widgets/dialogs.dart';
import '../widgets/list_widgets.dart';
import '../widgets/misc_widgets.dart';
import '../widgets/popup_menus.dart';

class SubjectEditRoute extends StatefulWidget {
  const SubjectEditRoute({Key? key}) : super(key: key);

  @override
  State<SubjectEditRoute> createState() => _SubjectEditRouteState();
}

class _SubjectEditRouteState extends State<SubjectEditRoute> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController coeffController = TextEditingController();
  final TextEditingController speakingController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    coeffController.dispose();
    speakingController.dispose();
    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSubjectDialog(context, nameController, coeffController, speakingController).then((_) => rebuild()),
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(translations.edit_subjects, style: const TextStyle(fontWeight: FontWeight.bold)),
        titleSpacing: 0,
        toolbarHeight: 64,
        actions: [
          SortSelector(rebuild: rebuild, type: SortType.subject),
        ],
      ),
      body: ShowCaseWidget(
        blurValue: 1,
        onFinish: () {
          setPreference<bool>("showcase_subject_edit", false);
          rebuild();
        },
        builder: Builder(builder: (context) {
          return SafeArea(
            top: false,
            bottom: false,
            child: Manager.termTemplate.isNotEmpty
                ? ReorderableListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    primary: true,
                    buildDefaultDragHandles: false,
                    onReorder: onReorderListView,
                    children: buildTiles(),
                  )
                : EmptyWidget(message: translations.no_subjects),
          );
        }),
      ),
    );
  }

  void onReorderListView(int oldIndex, int newIndex) {
    if (oldIndex == newIndex - 1) return;

    setPreference<int>("sort_mode${SortType.subject}", SortMode.custom);

    Manager.sortAll();

    var oldIndexes = getSubjectIndexes(oldIndex);
    var newIndexes = getSubjectIndexes(newIndex, addedIndex: 1);
    int oldIndex1 = oldIndexes[0], oldIndex2 = oldIndexes[1];
    int newIndex1 = newIndexes[0], newIndex2 = newIndexes[1];

    if (oldIndex1 == newIndex1 && oldIndex2 < newIndex2) {
      newIndex2--;
    }
    if (oldIndex1 < newIndex1 && oldIndex2 == -1) {
      newIndex1--;
    } else if (newIndex1 == oldIndex1 && oldIndex2 == -1 && newIndex2 != -1) {
      return;
    }

    List<List<Subject>> lists = [Manager.termTemplate];
    lists.addAll(Manager.getCurrentYear().terms.map((term) => term.subjects));

    for (List<Subject> list in lists) {
      Subject item;
      if (oldIndex2 == -1) {
        item = list.removeAt(oldIndex1);
      } else {
        item = list[oldIndex1].children.removeAt(oldIndex2);
        if (list[oldIndex1].children.isEmpty) list[oldIndex1].isGroup = false;
      }

      item.isChild = newIndex2 != -1;

      if (newIndex2 == -1) {
        list.insert(newIndex1, item);
      } else {
        list[newIndex1].children.insertAll(newIndex2, [item, ...item.children]);
        item.children.clear();
        item.isGroup = false;
        list[newIndex1].isGroup = true;
      }
    }

    serialize();
    Manager.calculate();
    rebuild();
  }

  List<Widget> buildTiles() {
    List<Widget> result = [];
    int reorderIndex = 0;

    for (int i = 0; i < Manager.termTemplate.length; i++) {
      Subject element = Manager.termTemplate[i];
      result.add(SubjectTile(
        key: ValueKey(element),
        s: element,
        listKey: GlobalKey(),
        index1: i,
        reorderIndex: reorderIndex,
        rebuild: rebuild,
        nameController: nameController,
        coeffController: coeffController,
        speakingController: speakingController,
      ));
      reorderIndex++;
      for (int j = 0; j < element.children.length; j++) {
        Subject child = element.children[j];
        result.add(SubjectTile(
          key: ValueKey(child),
          s: child,
          listKey: GlobalKey(),
          index1: i,
          index2: j,
          reorderIndex: reorderIndex,
          rebuild: rebuild,
          nameController: nameController,
          coeffController: coeffController,
          speakingController: speakingController,
        ));
        reorderIndex++;
      }
    }

    return result;
  }
}

List<int> getSubjectIndexes(int absoluteIndex, {int addedIndex = 0}) {
  int subjectCount = 0, index1 = 0, index2 = -1;

  for (int i = 0; i < Manager.termTemplate.length; i++) {
    int childAmount = Manager.termTemplate[i].children.length;
    if (subjectCount + childAmount + (childAmount > 0 ? addedIndex : 0) >= absoluteIndex) {
      break;
    }
    subjectCount += childAmount;
    index1 = i + 1;
    subjectCount++;
  }
  index2 = absoluteIndex - subjectCount - 1;

  return [index1, index2];
}
