import 'package:flutter/material.dart';
// import 'dart:io';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.gradient,
    this.borderColor,
    this.shadow = true,
    this.glassColor,
    this.thickness,
    this.lightIntensity,
    this.ambientStrength,
    this.blend,
    this.saturation,
    required this.child,
  });

  final EdgeInsets padding;
  final double borderRadius;
  final Gradient? gradient;
  final Color? borderColor;
  final bool shadow;
  final Color? glassColor;
  final double? thickness;
  final double? lightIntensity;
  final double? ambientStrength;
  final double? blend;
  final double? saturation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        color: (glassColor ?? Colors.white).withValues(alpha: 0.08),
        border: Border.all(color: (borderColor ?? Colors.white).withValues(alpha: 0.18)),
        boxShadow: shadow
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.borderColor,
    this.shadow = true,
    this.onTap,
    required this.child,
  });

  final EdgeInsets padding;
  final double borderRadius;
  final Color? borderColor;
  final bool shadow;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: (borderColor ?? Colors.white).withValues(alpha: 0.18)),
            boxShadow: shadow
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}