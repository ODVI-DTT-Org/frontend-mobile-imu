import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/client_attribute_filter.dart';
import '../../../shared/models/client_filter_options.dart';
import '../../../shared/models/location_filter.dart';
import '../../../shared/providers/client_attribute_filter_provider.dart';
import '../../../shared/providers/client_filter_options_provider.dart';
import '../../../shared/providers/location_filter_providers.dart';
import 'location_dropdown_section.dart';
import 'attribute_chips_section.dart';
import 'date_range_section.dart';

class FilterDrawer extends ConsumerStatefulWidget {
  const FilterDrawer({super.key});

  @override
  ConsumerState<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends ConsumerState<FilterDrawer> {
  late ClientAttributeFilter _draftAttrs;
  late LocationFilter _draftLocation;

  @override
  void initState() {
    super.initState();
    _draftAttrs = ref.read(clientAttributeFilterProvider);
    _draftLocation = ref.read(locationFilterProvider);
  }

  void _applyAndClose() {
    ref.read(clientAttributeFilterProvider.notifier).updateFilter(_draftAttrs);
    ref.read(locationFilterProvider.notifier).updateFilter(_draftLocation);
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _draftAttrs = ClientAttributeFilter.none();
      _draftLocation = const LocationFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(clientFilterOptionsProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 8,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.82,
          height: double.infinity,
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Location
                      LocationDropdownSection(
                        draftFilter: _draftLocation,
                        onChanged: (f) => setState(() => _draftLocation = f),
                      ),
                      const SizedBox(height: 20),
                      // 2. Visit Status
                      AttributeChipsSection(
                        draftFilter: _draftAttrs,
                        options: const ClientFilterOptions(),
                        onChanged: (f) => setState(() => _draftAttrs = f),
                        showVisitStatus: true,
                        showOthers: false,
                      ),
                      const SizedBox(height: 20),
                      // 3. Date Range (paired with visit status)
                      DateRangeSection(
                        draftFilter: _draftAttrs,
                        onChanged: (f) => setState(() => _draftAttrs = f),
                      ),
                      const SizedBox(height: 20),
                      // 4. Other attributes — Client Type, Market Type, Pension Type, Product Type, Loan Type
                      optionsAsync.when(
                        data: (options) => AttributeChipsSection(
                          draftFilter: _draftAttrs,
                          options: options,
                          onChanged: (f) => setState(() => _draftAttrs = f),
                          showVisitStatus: false,
                          showOthers: true,
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => AttributeChipsSection(
                          draftFilter: _draftAttrs,
                          options: const ClientFilterOptions(),
                          onChanged: (f) => setState(() => _draftAttrs = f),
                          showVisitStatus: false,
                          showOthers: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearAll,
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _applyAndClose,
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showFilterDrawer(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close filters',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const FilterDrawer(),
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}
