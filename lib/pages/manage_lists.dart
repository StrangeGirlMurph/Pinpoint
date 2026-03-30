import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/default_page.dart';

class ManageListsPage extends StatefulWidget {
  const ManageListsPage({super.key});

  @override
  State<ManageListsPage> createState() => _ManageListsPageState();
}

class _ManageListsPageState extends State<ManageListsPage> {
  List<EntryList> _lists = [];
  int? _editingListId;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadLists();
    _editFocusNode.addListener(() {
      if (!_editFocusNode.hasFocus && _editingListId != null) {
        _saveEditingList();
      }
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    final db = context.read<AppDatabase>();
    final lists = await db.getLists();
    if (mounted) {
      setState(() {
        _lists = lists;
      });
    }
  }

  Future<void> _addList() async {
    final db = context.read<AppDatabase>();
    await db.addList(name: 'New List');
    _loadLists();
  }

  Future<void> _deleteList(EntryList list) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: Text(
            'Are you sure you want to delete the "${list.name}" list and all of its entries? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final db = context.read<AppDatabase>();
      final storage = context.read<ImageStorage>();

      await db.deleteList(list.listId, storage);
      _loadLists();
    }
  }

  Future<void> _startEditing(EntryList list) async {
    setState(() {
      _editingListId = list.listId;
      _editController.text = list.name;
    });
    _editFocusNode.requestFocus();
  }

  Future<void> _saveEditingList() async {
    if (_editingListId == null) return;

    final newName = _editController.text.trim();
    final list = _lists.firstWhere((l) => l.listId == _editingListId);

    setState(() {
      _editingListId = null;
    });

    if (newName.isNotEmpty && newName != list.name) {
      final db = context.read<AppDatabase>();
      await db.updateList(list.copyWith(name: newName));
      _loadLists();
    }
  }

  Future<void> _editListColor(EntryList list) async {
    Color selectedColor = list.color;

    final color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              selectedColor = color;
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            labelTypes: const [],
            hexInputBar: true,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(selectedColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (color != null && color != list.color) {
      if (!mounted) return;
      final db = context.read<AppDatabase>();
      await db.updateList(list.copyWith(color: Value(color)));
      _loadLists();
      // To reflect color changes optionally in UI immediately, we call loadLists which triggers rebuild.
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final db = context.read<AppDatabase>();

    // We update UI immediately for snappy response
    setState(() {
      final item = _lists.removeAt(oldIndex);
      _lists.insert(newIndex, item);
    });

    await db.reorderLists(oldIndex, newIndex);
    _loadLists(); // Fetch accurate final data from db just to be in sync.
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + appbarHeight;

    return DefaultPage(
      name: "Manage Lists",
      floatingActionButton: FloatingActionButton(
        onPressed: _addList,
        tooltip: 'Add new list',
        child: const Icon(Icons.add),
      ),
      body: _lists.isEmpty
          ? const Center(child: Text("There are no lists. Please create one."))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: EdgeInsets.only(top: topPadding, bottom: 10),
              itemCount: _lists.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final list = _lists[index];
                return ListTile(
                  key: ValueKey(list.listId),
                  leading: GestureDetector(
                    onTap: () => _editListColor(list),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: list.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                  ),
                  title: _editingListId == list.listId
                      ? TextField(
                          controller: _editController,
                          focusNode: _editFocusNode,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            border: UnderlineInputBorder(),
                          ),
                          onSubmitted: (_) => _saveEditingList(),
                        )
                      : GestureDetector(
                          onTap: () => _startEditing(list),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              list.name,
                            ),
                          ),
                        ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.grey),
                        onPressed: () => _deleteList(list),
                        tooltip: 'Delete List',
                      ),
                      const SizedBox(width: 8),
                      ReorderableDragStartListener(
                        index: index,
                        child:
                            const Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
