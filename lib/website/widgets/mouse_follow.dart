import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MouseFollow extends StatefulWidget {
  final Widget child;
  final Color highlightColor;

  const MouseFollow({
    super.key,
    required this.child,
    this.highlightColor = Colors.white,
  });

  @override
  State<MouseFollow> createState() => _MouseFollowState();
}

class _MouseFollowState extends State<MouseFollow> {
  final GlobalKey _containerKey = GlobalKey();
  Offset _highlightPosition = Offset.zero;
  Size _highlightSize = Size.zero;

  void _updateHighlight(Offset position, Size size) {
    setState(() {
      _highlightPosition = position;
      _highlightSize = size;
    });
  }

  void _handleMouseMove(PointerEvent event) {
    final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Find which grid item is under the cursor using hit test
    final hitResult = HitTestResult();
    WidgetsBinding.instance.hitTest(hitResult, event.position);
    
    // Check if we hit a grid item
    for (final entry in hitResult.path) {
      if (entry.target is RenderBox) {
        final targetBox = entry.target as RenderBox;
        
        // Try to find the tech item by checking parent widgets
        final targetContext = targetBox.debugSemantics?.owner?.rootSemanticsNode;
        if (targetContext != null) {
          final itemPosition = targetBox.localToGlobal(Offset.zero, ancestor: renderBox);
          _updateHighlight(itemPosition, targetBox.size);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _handleMouseMove,
      child: Stack(
        children: [
          // Highlight box
          if (_highlightSize.width > 0 && _highlightSize.height > 0)
            Positioned(
              left: _highlightPosition.dx,
              top: _highlightPosition.dy,
              width: _highlightSize.width,
              height: _highlightSize.height,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.highlightColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: widget.highlightColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          // Content
          Container(
            key: _containerKey,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

