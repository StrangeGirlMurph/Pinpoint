import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/settings.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/drawer.dart';
import 'package:pinpoint/widgets/bottom_sheet.dart';
import 'package:pinpoint/widgets/scaffold.dart';
import 'package:pinpoint/util/list.dart';
import 'package:pinpoint/widgets/dropdown.dart';

class ListViewPage extends StatefulWidget {
  const ListViewPage({super.key});

  @override
  State<ListViewPage> createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  List<EntryList> _lists = [];
  EntryList? _selectedList;
  List<Entry> _entries = [];

  final _dateFormatter = DateFormat('dd.MM.yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final settings = context.read<Settings>();
    final lists = await db.getLists();

    if (mounted) {
      final newSelectedList = determineSelectedList(
        lists: lists,
        currentSelectedList: _selectedList,
        lastListId: settings.get(Settings.lastListId),
      );

      setState(() {
        _lists = lists;
        _selectedList = newSelectedList;
        if (_selectedList == null) {
          _entries = [];
        }
      });
      if (_selectedList != null) {
        _loadEntries(_selectedList!.listId);
      }
    }
  }

  Future<void> _loadEntries(int listId) async {
    final db = context.read<AppDatabase>();
    final entries = listId == -1
        ? await db.getAllEntries()
        : await db.getListEntries(listId);

    // Sort in memory to show newest first
    entries.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });

    if (mounted) {
      setState(() {
        _entries = entries;
      });
    }
  }

  Future<void> _addNewEntry() async {
    if (!mounted || !canAddEntryToSelectedList(context, _selectedList)) return;

    final db = context.read<AppDatabase>();
    final entryId = await db.addEntry(
      listId: _selectedList!.listId,
      date: DateTime.now(),
    );

    final newEntry = await db.getEntry(entryId);

    if (newEntry != null && mounted) {
      _showBottomSheet(newEntry);
    }

    _loadEntries(_selectedList!.listId);
  }

  void _showBottomSheet(Entry entry) {
    showEntryEditBottomSheet(
      context,
      entry,
      onSaved: () => _loadEntries(_selectedList!.listId),
      onDeleted: () => _loadEntries(_selectedList!.listId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + appbarHeight;

    return AnnotatedScaffold(
      drawer: CDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEntry,
        tooltip: 'Add new entry',
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          // List View
          Positioned.fill(
            child: _entries.isEmpty
                ? (_selectedList == null
                    ? const Center(
                        child: Text("Please create a list to use this page!"))
                    : const Center(child: Text("No entries in this list yet.")))
                : ListView.builder(
                    padding: EdgeInsets.only(top: topPadding, bottom: 10),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      // Format the date DD.MM.YYYY HH:MM:SS
                      final dateString = entry.date != null
                          ? _dateFormatter.format(entry.date!)
                          : 'No date';

                      return ListTile(
                        leading: Icon(
                          (entry.latitude != null && entry.longitude != null)
                              ? Icons.location_on
                              : Icons.location_off,
                          color: _selectedList?.listId == -1
                              ? _lists
                                  .firstWhere((l) => l.listId == entry.listId,
                                      orElse: () => _lists.first)
                                  .color
                              : (_selectedList?.color ?? Colors.red),
                        ),
                        title: Text(
                          entry.description ?? 'No description',
                          maxLines: 1,
                          style: TextStyle(overflow: TextOverflow.ellipsis),
                        ),
                        subtitle: Text(dateString),
                        onTap: () => _showBottomSheet(entry),
                        trailing: const Icon(Icons.chevron_right),
                      );
                    },
                  ),
          ),

          // App bar
          Positioned(
            top: 0,
            left: 0,
            child: CoreAppbar([
              Expanded(
                child: ListDropdown(
                  selectedList: _selectedList,
                  lists: _lists,
                  onSelected: (newList) {
                    if (newList != null) {
                      setState(() {
                        _selectedList = newList;
                      });
                      _loadEntries(newList.listId);
                    }
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
