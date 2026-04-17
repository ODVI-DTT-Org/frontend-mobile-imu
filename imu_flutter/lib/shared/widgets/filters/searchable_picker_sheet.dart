import 'package:flutter/material.dart';

class SearchablePickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final Set<String> selectedItems;
  final bool multiSelect;
  final bool showAllOption;
  final void Function(Set<String> selected) onConfirm;

  const SearchablePickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.multiSelect,
    required this.onConfirm,
    this.showAllOption = false,
  });

  static Future<Set<String>?> show({
    required BuildContext context,
    required String title,
    required List<String> items,
    required Set<String> selectedItems,
    required bool multiSelect,
    bool showAllOption = false,
  }) async {
    Set<String>? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SearchablePickerSheet(
          title: title,
          items: items,
          selectedItems: selectedItems,
          multiSelect: multiSelect,
          showAllOption: showAllOption,
          onConfirm: (s) {
            result = s;
            Navigator.pop(ctx);
          },
        ),
      ),
    );
    return result;
  }

  @override
  State<SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<SearchablePickerSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedItems);
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) => item.toLowerCase().contains(q)).toList();
  }

  void _toggle(String item) {
    setState(() {
      if (widget.multiSelect) {
        _selected.contains(item) ? _selected.remove(item) : _selected.add(item);
      } else {
        _selected = {item};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              if (widget.showAllOption)
                ListTile(
                  dense: true,
                  title: const Text('All', style: TextStyle(fontWeight: FontWeight.w500)),
                  leading: widget.multiSelect
                      ? Checkbox(
                          value: _selected.isEmpty,
                          onChanged: (_) => setState(() => _selected.clear()),
                        )
                      : Radio<bool>(
                          value: true,
                          groupValue: _selected.isEmpty,
                          onChanged: (_) => setState(() => _selected.clear()),
                        ),
                  onTap: () => setState(() => _selected.clear()),
                ),
              ..._filtered.map((item) => ListTile(
                    dense: true,
                    title: Text(item),
                    leading: widget.multiSelect
                        ? Checkbox(
                            value: _selected.contains(item),
                            onChanged: (_) => _toggle(item),
                          )
                        : Radio<String>(
                            value: item,
                            groupValue: _selected.isEmpty ? null : _selected.first,
                            onChanged: (_) => _toggle(item),
                          ),
                    onTap: () => _toggle(item),
                  )),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onConfirm(_selected),
                child: const Text('Confirm'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
