import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktop;
        } else if (constraints.maxWidth >= 650) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// A wrapper to ensure content doesn't stretch too wide on desktop.
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool fillHeight;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 1000,
    this.fillHeight = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: fillHeight ? MediaQuery.of(context).size.height : 0,
        ),
        child: child,
      ),
    );
  }
}
