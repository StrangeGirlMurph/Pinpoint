import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/settings.dart';
import 'package:pinpoint/util/list.dart';

class ListDropdown extends StatelessWidget {
  final EntryList? selectedList;
  final List<EntryList> lists;
  final Function(EntryList?) onSelected;

  const ListDropdown({
    super.key,
    required this.selectedList,
    required this.lists,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<EntryList>(
      initialSelection: selectedList,
      enabled: lists.isNotEmpty,
      hintText: lists.isEmpty ? 'No lists available' : 'Select a list',
      expandedInsets: EdgeInsets.zero,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        isDense: true,
      ),
      textStyle: TextStyle(
        fontSize: 20,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
        fontStyle: selectedList?.listId == -1 ? FontStyle.italic : null,
      ),
      dropdownMenuEntries: [
        ...lists.map((list) {
          return DropdownMenuEntry<EntryList>(
            value: list,
            label: list.name,
            labelWidget: Text(
              list.name,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          );
        }),
        if (lists.length >= 2)
          DropdownMenuEntry<EntryList>(
            value: everythingList,
            label: everythingList.name,
            labelWidget: Text(
              everythingList.name,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
      ],
      onSelected: (EntryList? newList) {
        if (newList != null && newList.listId != selectedList?.listId) {
          context.read<Settings>().set(Settings.lastListId, newList.listId);
          onSelected(newList);
        }
      },
    );
  }
}
