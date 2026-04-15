// lib/shared/widgets/filters/client_attribute_filter_bottom_sheet_dropdown.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/client_attribute_filter.dart';
import '../../models/client_filter_options.dart';
import '../../providers/client_filter_options_provider.dart';
import '../../providers/client_attribute_filter_provider.dart';
import '../../../features/clients/data/models/client_model.dart';
import 'client_attribute_filter_helpers.dart';

/// Improved client attribute filter bottom sheet with dropdown UI
/// Replaces radio buttons with dropdowns for Option 1 design
class ClientAttributeFilterDropdownBottomSheet extends ConsumerStatefulWidget {
  final Function(ClientAttributeFilter) onApply;
  final VoidCallback onClearAll;

  const ClientAttributeFilterDropdownBottomSheet({
    super.key,
    required this.onApply,
    required this.onClearAll,
  });

  @override
  ConsumerState<ClientAttributeFilterDropdownBottomSheet> createState() =>
      _ClientAttributeDropdownBottomSheetState();
}

class _ClientAttributeDropdownBottomSheetState
    extends ConsumerState<ClientAttributeFilterDropdownBottomSheet> {
  ClientType? _selectedClientType;
  MarketType? _selectedMarketType;
  PensionType? _selectedPensionType;
  ProductType? _selectedProductType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentFilter = ref.read(clientAttributeFilterProvider);
      if (mounted) {
        setState(() {
          _selectedClientType = currentFilter.clientType;
          _selectedMarketType = currentFilter.marketType;
          _selectedPensionType = currentFilter.pensionType;
          _selectedProductType = currentFilter.productType;
        });
      }
    });
  }

  void _handleApply() {
    final filter = ClientAttributeFilter(
      clientType: _selectedClientType,
      marketType: _selectedMarketType,
      pensionType: _selectedPensionType,
      productType: _selectedProductType,
    );
    widget.onApply(filter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filterOptionsAsync = ref.watch(clientFilterOptionsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: filterOptionsAsync.when(
              data: (options) => _buildContent(options as ClientFilterOptions),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildErrorState(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              const Expanded(
                child: Text(
                  'Filter Clients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
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

  Widget _buildContent(ClientFilterOptions options) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FilterDropdown<ClientType>(
          title: 'Client Type',
          icon: LucideIcons.users,
          options: options.clientTypes,
          selectedOption: _selectedClientType,
          onOptionSelected: (value) => setState(() => _selectedClientType = value),
          getLabel: formatClientType,
          getIcon: getClientTypeIcon,
        ),
        const SizedBox(height: 16),
        _FilterDropdown<MarketType>(
          title: 'Market Type',
          icon: LucideIcons.building,
          options: options.marketTypes,
          selectedOption: _selectedMarketType,
          onOptionSelected: (value) => setState(() => _selectedMarketType = value),
          getLabel: formatMarketType,
          getIcon: getMarketTypeIcon,
        ),
        const SizedBox(height: 16),
        _FilterDropdown<PensionType>(
          title: 'Pension Type',
          icon: LucideIcons.creditCard,
          options: options.pensionTypes,
          selectedOption: _selectedPensionType,
          onOptionSelected: (value) => setState(() => _selectedPensionType = value),
          getLabel: formatPensionType,
          getIcon: getPensionTypeIcon,
        ),
        const SizedBox(height: 16),
        _FilterDropdown<ProductType>(
          title: 'Product Type',
          icon: LucideIcons.package,
          options: options.productTypes,
          selectedOption: _selectedProductType,
          onOptionSelected: (value) => setState(() => _selectedProductType = value),
          getLabel: formatProductType,
          getIcon: getProductTypeIcon,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Failed to load filter options'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(clientFilterOptionsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final hasFilters = _selectedClientType != null ||
        _selectedMarketType != null ||
        _selectedPensionType != null ||
        _selectedProductType != null;

    final activeCount = [_selectedClientType, _selectedMarketType, _selectedPensionType, _selectedProductType]
        .where((f) => f != null)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            if (hasFilters)
              TextButton(
                onPressed: _handleClearAllLocal,
                child: const Text('Clear All'),
              ),
            const Spacer(),
            Text(
              '$activeCount selected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: hasFilters ? _handleApply : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasFilters ? const Color(0xFF0F172A) : Colors.grey[300],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleClearAllLocal() {
    setState(() {
      _selectedClientType = null;
      _selectedMarketType = null;
      _selectedPensionType = null;
      _selectedProductType = null;
    });
  }
}

/// Dropdown filter widget for each attribute type
class _FilterDropdown<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<T> options;
  final T? selectedOption;
  final Function(T) onOptionSelected;
  final String Function(T) getLabel;
  final IconData? Function(T)? getIcon;

  const _FilterDropdown({
    required this.title,
    required this.icon,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.getLabel,
    this.getIcon,
  });

  @override
  State<_FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<_FilterDropdown<T>> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _selectOption(T option) {
    setState(() {
      _isExpanded = false;
    });
    widget.onOptionSelected(option);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = widget.selectedOption != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSelection
              ? theme.colorScheme.primary.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: hasSelection
                        ? theme.colorScheme.primary
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: hasSelection
                            ? theme.colorScheme.primary
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    hasSelection ? widget.getLabel(widget.selectedOption!) : 'All',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasSelection
                          ? theme.colorScheme.primary
                          : Colors.grey[500],
                    ),
                  ),
                  Icon(
                    _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: hasSelection
                        ? theme.colorScheme.primary
                        : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSelected = option == widget.selectedOption;
                  final optionIcon = widget.getIcon?.call(option);

                  return InkWell(
                    onTap: () => _selectOption(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      child: Row(
                        children: [
                          if (optionIcon != null) ...[
                            Icon(
                              optionIcon,
                              size: 16,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              widget.getLabel(option),
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              LucideIcons.check,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
