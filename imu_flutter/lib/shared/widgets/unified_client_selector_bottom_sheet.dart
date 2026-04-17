// lib/shared/widgets/unified_client_selector_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/client_attribute_filter.dart';
import '../models/location_filter.dart';
import '../../features/clients/data/models/client_model.dart';
import 'client_filter_chips.dart';
import 'client_attribute_filter_bottom_sheet.dart';
import 'location_filter_bottom_sheet.dart';
import '../providers/client_attribute_filter_provider.dart';
import '../providers/location_filter_providers.dart';
import '../../features/clients/presentation/widgets/client_filter_icon_button.dart';

class UnifiedClientSelectorBottomSheet extends ConsumerStatefulWidget {
  final String context; // 'my_day' or 'itinerary'
  final Function(Client) onClientSelected;

  const UnifiedClientSelectorBottomSheet({
    super.key,
    required this.context,
    required this.onClientSelected,
  });

  @override
  ConsumerState<UnifiedClientSelectorBottomSheet> createState() =>
      _UnifiedClientSelectorBottomSheetState();
}

class _UnifiedClientSelectorBottomSheetState
    extends ConsumerState<UnifiedClientSelectorBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _showAttributeFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ClientAttributeFilterBottomSheet(
        onApply: (filter) {
          ref.read(clientAttributeFilterProvider.notifier).state = filter;
          setState(() {});
        },
      ),
    );
  }

  void _showLocationFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LocationFilterBottomSheet(
        onApply: (filter) {
          ref.read(locationFilterProvider.notifier).updateFilter(filter);
          setState(() {});
        },
      ),
    );
  }

  void _clearAllFilters() {
    ref.read(locationFilterProvider.notifier).clear();
    ref.read(clientAttributeFilterProvider.notifier).clear();
    setState(() {});
  }

  void _removeFilter(FilterType type) {
    switch (type) {
      case FilterType.location:
        ref.read(locationFilterProvider.notifier).clear();
        break;
      case FilterType.clientType:
      case FilterType.marketType:
      case FilterType.pensionType:
      case FilterType.productType:
        ref.read(clientAttributeFilterProvider.notifier).clear();
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locationFilter = ref.watch(locationFilterProvider);
    final attributeFilter = ref.watch(clientAttributeFilterProvider);
    final title = widget.context == 'my_day' ? 'Add to My Day' : 'Add to Itinerary';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(title),
          _buildSearchBar(),
          ClientFilterChips(
            locationFilter: locationFilter,
            attributeFilter: attributeFilter,
            onRemove: _removeFilter,
            onClearAll: _clearAllFilters,
          ),
          Expanded(
            child: _buildClientList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search client name...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClientFilterIconButton(
            showAttributeOnly: true,
            onPressed: _showAttributeFilters,
          ),
          ClientFilterIconButton(
            showLocationOnly: true,
            onPressed: _showLocationFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildClientList() {
    // This should display filtered clients based on current filters
    // Implementation depends on how clients are fetched
    // For now, showing placeholder
    return const Center(
      child: Text('Client list will be displayed here'),
    );
  }
}
