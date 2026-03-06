// ABOUTME: Responsive breakpoint constants and helpers.
// ABOUTME: Single breakpoint at 1024px separates mobile from desktop layout.

import 'package:flutter/widgets.dart';

const double desktopBreakpoint = 1024;

bool isDesktop(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}
