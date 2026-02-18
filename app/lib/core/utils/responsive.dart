import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
/// Supports: Mobile (< 600), Tablet (600-1024), Desktop (> 1024)
class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Get responsive value based on device type
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return value(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    return value(context: context, mobile: 16.0, tablet: 32.0, desktop: 64.0);
  }

  /// Get number of grid columns
  static int gridColumns(BuildContext context) {
    return value(context: context, mobile: 1, tablet: 2, desktop: 3);
  }

  /// Get responsive font size multiplier
  static double fontScale(BuildContext context) {
    return value(context: context, mobile: 1.0, tablet: 1.1, desktop: 1.15);
  }

  /// Get max content width for centered layouts
  static double maxContentWidth(BuildContext context) {
    return value(
      context: context,
      mobile: double.infinity,
      tablet: 768.0,
      desktop: 1200.0,
    );
  }

  /// Check if should show sidebar (desktop only)
  static bool shouldShowSidebar(BuildContext context) => isDesktop(context);

  /// Check if should use bottom navigation (mobile/tablet)
  static bool shouldShowBottomNav(BuildContext context) => !isDesktop(context);
}

enum DeviceType { mobile, tablet, desktop }

/// Extension on BuildContext for easy responsive access
extension ResponsiveContext on BuildContext {
  /// Quick access to device type
  DeviceType get deviceType => Responsive.getDeviceType(this);

  /// Quick check for mobile
  bool get isMobile => Responsive.isMobile(this);

  /// Quick check for tablet
  bool get isTablet => Responsive.isTablet(this);

  /// Quick check for desktop
  bool get isDesktop => Responsive.isDesktop(this);

  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Responsive padding
  EdgeInsets get responsivePadding => Responsive.padding(this);

  /// Responsive horizontal padding
  double get responsiveHorizontalPadding => Responsive.horizontalPadding(this);

  /// Number of grid columns based on screen size
  int get gridColumns => Responsive.gridColumns(this);

  /// Font scale factor
  double get fontScale => Responsive.fontScale(this);

  /// Max content width
  double get maxContentWidth => Responsive.maxContentWidth(this);
}

/// Responsive layout widget that builds different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.tabletBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Centered content wrapper with max width constraint
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.maxContentWidth,
        ),
        padding: padding ?? context.responsivePadding,
        child: child,
      ),
    );
  }
}

/// Responsive grid that adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.value(
      context: context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}
