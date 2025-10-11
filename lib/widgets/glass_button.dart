import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key, 
    required this.onPressed, 
    required this.child, 
    this.borderRadius = 14, 
    this.enabled = true,
    this.glassColor,
    this.borderColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final bool enabled;
  final Color? glassColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && onPressed != null;
    
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isEnabled ? onPressed : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
            decoration: BoxDecoration(
              color: (glassColor ?? Colors.white).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: (borderColor ?? Colors.white).withValues(alpha: 0.18)),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x24000000), blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key, 
    required this.icon, 
    required this.onPressed, 
    this.borderRadius = 10,
    this.iconColor,
    this.size,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double borderRadius;
  final Color? iconColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Icon(
              icon,
              size: size ?? 17,
              color: iconColor ?? Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}


