// lib/shared/widgets/client_attribute_filter_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/client_attribute_filter.dart';
import '../models/client_filter_options.dart';
import '../providers/client_filter_options_provider.dart';
import '../providers/client_attribute_filter_provider.dart';
import '../../features/clients/data/models/client_model.dart';

class ClientAttributeFilterBottomSheet extends ConsumerStatefulWidget {
  final Function(ClientAttributeFilter) onApply;

  const ClientAttributeFilterBottomSheet({
    super.key,
    required this.onApply,
  });

  @override
  ConsumerState<ClientAttributeFilterBottomSheet> createState() =>
      _ClientAttributeFilterBottomSheetState();
}

class _ClientAttributeFilterBottomSheetState
    extends ConsumerState<ClientAttributeFilterBottomSheet> {
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

  void _handleClearAll() {
    setState(() {
      _selectedClientType = null;
      _selectedMarketType = null;
      _selectedPensionType = null;
      _selectedProductType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterOptionsAsync = ref.watch(clientFilterOptionsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: filterOptionsAsync.when(
              data: (options) => _buildContent(options),
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
                  'Filter by Client Attributes',
                  style: TextStyle(
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

  Widget _buildContent(ClientFilterOptions options) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FilterSection<ClientType>(
          title: 'Client Type',
          options: options.clientTypes,
          selectedOption: _selectedClientType,
          onOptionSelected: (value) =>
              setState(() => _selectedClientType = value),
          getLabel: (type) => type.name.toUpperCase(),
        ),
        _FilterSection<MarketType>(
          title: 'Market Type',
          options: options.marketTypes,
          selectedOption: _selectedMarketType,
          onOptionSelected: (value) =>
              setState(() => _selectedMarketType = value),
          getLabel: (type) =>
              type.name[0].toUpperCase() + type.name.substring(1),
        ),
        _FilterSection<PensionType>(
          title: 'Pension Type',
          options: options.pensionTypes,
          selectedOption: _selectedPensionType,
          onOptionSelected: (value) =>
              setState(() => _selectedPensionType = value),
          getLabel: (type) => type.name.toUpperCase(),
        ),
        _FilterSection<ProductType>(
          title: 'Product Type',
          options: options.productTypes,
          selectedOption: _selectedProductType,
          onOptionSelected: (value) =>
              setState(() => _selectedProductType = value),
          getLabel: (type) {
            switch (type) {
              case ProductType.sssPensioner:
                return 'SSS Pensioner';
              case ProductType.gsisPensioner:
                return 'GSIS Pensioner';
              case ProductType.private:
                return 'Private';
            }
          },
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

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (hasFilters)
            TextButton(
              onPressed: _handleClearAll,
              child: const Text('Clear All'),
            ),
          const Spacer(),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: _handleApply,
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T? selectedOption;
  final Function(T) onOptionSelected;
  final String Function(T) getLabel;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.getLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: Text(title),
      initiallyExpanded: true,
      children: options.map((option) {
        return RadioListTile<T>(
          title: Text(getLabel(option)),
          value: option,
          groupValue: selectedOption,
          onChanged: (value) {
            if (value != null) {
              onOptionSelected(value);
            }
          },
        );
      }).toList(),
    );
  }
}
