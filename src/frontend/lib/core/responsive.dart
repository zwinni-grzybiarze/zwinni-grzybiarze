import 'package:flutter/material.dart';

/// Breakpoints for OnlyShrooms layout adaptation.
enum AppSizeClass { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  /// Portrait phone / narrow web pane.
  bool get isCompact => screenWidth < 600;

  bool get isMedium => screenWidth >= 600 && screenWidth < 1024;

  bool get isExpanded => screenWidth >= 1024;

  AppSizeClass get sizeClass {
    if (isCompact) return AppSizeClass.compact;
    if (isMedium) return AppSizeClass.medium;
    return AppSizeClass.expanded;
  }

  /// Page gutters: tighter on phones, roomier on desktop.
  EdgeInsets get pagePadding {
    switch (sizeClass) {
      case AppSizeClass.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
      case AppSizeClass.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
      case AppSizeClass.expanded:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double get contentMaxWidth {
    switch (sizeClass) {
      case AppSizeClass.compact:
        return double.infinity;
      case AppSizeClass.medium:
        return 720;
      case AppSizeClass.expanded:
        return 960;
    }
  }

  /// Form pages stay a bit narrower for readability.
  double get formMaxWidth => isCompact ? double.infinity : 640;
}

/// Centers content and caps width on larger screens.
/// Fills available height so [Column]/[Expanded] layouts work.
class AdaptivePage extends StatelessWidget {
  const AdaptivePage({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final widthCap = maxWidth ?? context.contentMaxWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widthCap.isFinite
            ? constraints.maxWidth.clamp(0, widthCap).toDouble()
            : constraints.maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.hasBoundedHeight
                ? constraints.maxHeight
                : null,
            child: Padding(
              padding: padding ?? context.pagePadding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
