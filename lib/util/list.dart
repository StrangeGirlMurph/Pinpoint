import 'package:flutter/material.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/util/snackbar.dart';

const EntryList everythingList = EntryList(
  listId: -1,
  order: -1,
  name: 'Everything',
  color: Colors.transparent,
);

EntryList? determineSelectedList({
  required List<EntryList> lists,
  required EntryList? currentSelectedList,
  required int lastListId,
}) {
  if (lists.isEmpty) {
    return null;
  }

  if (currentSelectedList == null) {
    if (lastListId == -1 && lists.length >= 2) {
      return everythingList;
    } else {
      return lists.cast<EntryList?>().firstWhere(
            (l) => l!.listId == lastListId,
            orElse: () => lists.first,
          );
    }
  }

  final currentListExists =
      lists.any((l) => l.listId == currentSelectedList.listId);

  if ((currentSelectedList.listId != -1 && !currentListExists) ||
      (currentSelectedList.listId == -1 && lists.length < 2)) {
    return lists.first;
  }

  return currentSelectedList;
}

bool canAddEntryToSelectedList(BuildContext context, EntryList? selectedList) {
  if (selectedList == null) {
    showSnackBar(context, 'Please create a list first');
    return false;
  }
  if (selectedList.listId == -1) {
    showSnackBar(context, 'Please select a specific list first');
    return false;
  }
  return true;
}

Future<EntryList?> showSelectListDialog(
  BuildContext context,
  List<EntryList> lists, {
  int? currentListId,
  String? title,
}) async {
  if (lists.isEmpty) return null;
  if (lists.length == 1) return lists.first;

  return showDialog<EntryList>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: lists
                .map(
                  (list) => ListTile(
                    leading: Icon(Icons.circle, color: list.color),
                    title: Text(list.name),
                    selected: list.listId == currentListId,
                    onTap: () => Navigator.of(context).pop(list),
                  ),
                )
                .toList(),
          ),
        ),
      );
    },
  );
}
