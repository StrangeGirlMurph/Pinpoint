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
