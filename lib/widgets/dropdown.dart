import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/settings.dart';
import 'package:pinpoint/util/list.dart';
import 'package:pinpoint/widgets/list_dot.dart';

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
    Widget? leadingIcon;
    if (selectedList != null) {
      leadingIcon = Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: selectedList!.listId == -1
            ? const ListColorDot.rainbow(size: 24)
            : ListColorDot(color: selectedList!.color, size: 24),
      );
    }

    return DropdownMenu<EntryList>(
      key: ValueKey(selectedList?.listId),
      initialSelection: selectedList,
      leadingIcon: leadingIcon,
      enabled: lists.isNotEmpty,
      hintText: lists.isEmpty ? 'No lists available' : 'Select a list',
      expandedInsets: EdgeInsets.zero,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        isDense: true,
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
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
            labelWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListColorDot(color: list.color, size: 16),
                const SizedBox(width: 8),
                Text(
                  list.name,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            ),
          );
        }),
        if (lists.length >= 2)
          DropdownMenuEntry<EntryList>(
            value: everythingList,
            label: everythingList.name,
            labelWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListColorDot.rainbow(size: 16),
                const SizedBox(width: 8),
                Text(
                  everythingList.name,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
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
