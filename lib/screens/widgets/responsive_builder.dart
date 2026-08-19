import 'dart:io';

import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  const Responsive({
    required this.mobileBuilder,
    required this.tabletBuilder,
    required this.desktopBuilder,
    super.key,
  });

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) mobileBuilder;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) tabletBuilder;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) desktopBuilder;

  static const double _mobile = 650;
  static const double _tablet = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < _tablet &&
      MediaQuery.of(context).size.width >= _mobile;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _tablet;

  static bool isDesktopPlatform() =>
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _tablet) {
          return desktopBuilder(context, constraints);
        } else if (constraints.maxWidth >= _mobile) {
          return tabletBuilder(context, constraints);
        } else {
          return mobileBuilder(context, constraints);
        }
      },
    );
  }
}
