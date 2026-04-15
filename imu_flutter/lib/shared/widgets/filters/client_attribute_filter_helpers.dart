// lib/shared/widgets/filters/client_attribute_filter_helpers.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';

/// Helper functions for client attribute filter display

/// Format ClientType enum for display
String formatClientType(ClientType? type) {
  if (type == null) return 'All';
  switch (type) {
    case ClientType.potential:
      return 'Potential';
    case ClientType.existing:
      return 'Existing';
  }
}

/// Get icon for ClientType
IconData? getClientTypeIcon(ClientType? type) {
  if (type == null) return null;
  switch (type) {
    case ClientType.potential:
      return LucideIcons.userPlus;
    case ClientType.existing:
      return LucideIcons.users;
  }
}

/// Format MarketType enum for display
String formatMarketType(MarketType? type) {
  if (type == null) return 'All';
  switch (type) {
    case MarketType.residential:
      return 'Residential';
    case MarketType.commercial:
      return 'Commercial';
    case MarketType.industrial:
      return 'Industrial';
  }
}

/// Get icon for MarketType
IconData? getMarketTypeIcon(MarketType? type) {
  if (type == null) return null;
  switch (type) {
    case MarketType.residential:
      return LucideIcons.home;
    case MarketType.commercial:
      return LucideIcons.building2;
    case MarketType.industrial:
      return LucideIcons.factory;
  }
}

/// Format PensionType enum for display
String formatPensionType(PensionType? type) {
  if (type == null) return 'All';
  switch (type) {
    case PensionType.sss:
      return 'SSS';
    case PensionType.gsis:
      return 'GSIS';
    case PensionType.private:
      return 'Private';
    case PensionType.none:
      return 'None';
  }
}

/// Get icon for PensionType
IconData? getPensionTypeIcon(PensionType? type) {
  if (type == null) return null;
  switch (type) {
    case PensionType.sss:
      return LucideIcons.landmark;
    case PensionType.gsis:
      return LucideIcons.building2;
    case PensionType.private:
      return LucideIcons.briefcase;
    case PensionType.none:
      return LucideIcons.minusCircle;
  }
}

/// Format ProductType enum for display
String formatProductType(ProductType? type) {
  if (type == null) return 'All';
  switch (type) {
    case ProductType.bfpActive:
      return 'BFP ACTIVE';
    case ProductType.bfpPension:
      return 'BFP PENSION';
    case ProductType.pnpPension:
      return 'PNP PENSION';
    case ProductType.napolcom:
      return 'NAPOLCOM';
    case ProductType.bfpStp:
      return 'BFP STP';
  }
}

/// Get icon for ProductType
IconData? getProductTypeIcon(ProductType? type) {
  if (type == null) return null;
  switch (type) {
    case ProductType.bfpActive:
      return LucideIcons.shield;
    case ProductType.bfpPension:
      return LucideIcons.shieldCheck;
    case ProductType.pnpPension:
      return LucideIcons.badgeCheck;
    case ProductType.napolcom:
      return LucideIcons.fileText;
    case ProductType.bfpStp:
      return LucideIcons.fileCheck;
  }
}
