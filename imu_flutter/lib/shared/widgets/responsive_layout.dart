import 'package:flutter/material.dart';

/// Responsive layout detection and utilities
class ResponsiveLayout {
  ResponsiveLayout._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if device is mobile (phone)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Check if device is landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get device type
  static DeviceType getDeviceType(BuildContext context) {
    if (isMobile(context)) return DeviceType.mobile;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get responsive value based on device type
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return responsive(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(BuildContext context) {
    return responsive(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    return responsive(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

  /// Get content max width
  static double getContentMaxWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 700,
      desktop: 900,
    );
  }
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveLayout.getDeviceType(context));
  }
}

/// Responsive layout widget with separate builders
class ResponsiveLayoutWidget extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveLayoutWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    if (ResponsiveLayout.isTablet(context) && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}

/// Master-detail split view for tablets
class MasterDetailSplitView extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final double masterWidth;
  final double detailMinWidth;
  final double dividerWidth;

  const MasterDetailSplitView({
    super.key,
    required this.master,
    this.detail,
    this.masterWidth = 350,
    this.detailMinWidth = 400,
    this.dividerWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isTablet(context) && !ResponsiveLayout.isDesktop(context)) {
      // On mobile, just show master or detail
      return detail ?? master;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Master panel
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        // Divider
        Container(
          width: dividerWidth,
          color: Colors.grey[300],
        ),
        // Detail panel
        Expanded(
          child: detail ?? _buildEmptyDetail(context),
        ),
      ],
    );
  }

  Widget _buildEmptyDetail(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.select_all_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select an item to view details',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Side sheet for tablets
class SideSheet extends StatelessWidget {
  final Widget child;
  final double? width;
  final bool showCloseButton;
  final String? title;
  final VoidCallback? onClose;

  const SideSheet({
    super.key,
    required this.child,
    this.width,
    this.showCloseButton = true,
    this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sheetWidth = width ?? ResponsiveLayout.responsive(
      context,
      mobile: MediaQuery.of(context).size.width,
      tablet: 400.0,
      desktop: 450.0,
    );

    return Container(
      width: sheetWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || showCloseButton)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (showCloseButton)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose ?? () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Show side sheet as overlay
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? width,
    bool showCloseButton = true,
    String? title,
    VoidCallback? onClose,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SideSheet(
            width: width,
            showCloseButton: showCloseButton,
            title: title,
            onClose: onClose ?? () => Navigator.pop(context),
            child: child,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    );
  }
}
