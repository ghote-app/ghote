import 'package:flutter/widgets.dart';

class Responsive {
  Responsive._();

  // Horizontal page padding relative to width, clamped to sane bounds
  static EdgeInsets pagePadding(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double horizontal = (w * 0.05).clamp(16.0, 28.0);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  // Vertical spacing helpers based on height
  static double spaceXS(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    return (h * 0.008).clamp(6.0, 10.0);
  }

  static double spaceS(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    return (h * 0.015).clamp(10.0, 16.0);
  }

  static double spaceM(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    return (h * 0.03).clamp(16.0, 28.0);
  }

  static double spaceL(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    return (h * 0.05).clamp(24.0, 56.0);
  }

  // Avatar/icon baseline sizes scaled by width
  static double avatarM(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return (w * 0.18).clamp(56.0, 80.0);
  }

  // Input padding tuned for text fields
  static EdgeInsets inputContentPadding(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double hPad = (w * 0.045).clamp(16.0, 22.0);
    return EdgeInsets.symmetric(horizontal: hPad, vertical: 14.0);
  }
}


