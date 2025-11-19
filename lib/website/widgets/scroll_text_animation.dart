import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScrollTextAnimation extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;
  final ScrollController scrollController;

  const ScrollTextAnimation({
    super.key,
    required this.text,
    required this.scrollController,
    this.fontSize = 200,
    this.color = Colors.white,
  });

  @override
  State<ScrollTextAnimation> createState() => _ScrollTextAnimationState();
}

class _ScrollTextAnimationState extends State<ScrollTextAnimation> {
  final Map<int, double> _letterOffsets = {};
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize letter offsets
    for (int i = 0; i < widget.text.length; i++) {
      _letterOffsets[i] = 0.0;
    }
    // Listen to scroll changes
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    _updateScrollProgress();
  }

  void _updateScrollProgress() {
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final widgetTop = position.dy;
    final widgetHeight = renderBox.size.height;
    
    // Calculate scroll progress based on widget position
    // Animation triggers when widget enters viewport (40% to 60% of screen)
    final viewportTop = screenHeight * 0.4;
    final viewportBottom = screenHeight * 0.6;
    
    // Check if widget is in the animation zone
    final widgetBottom = widgetTop + widgetHeight;
    final isInViewport = widgetBottom > viewportTop && widgetTop < viewportBottom;
    
    if (isInViewport) {
      // Calculate progress: 0 when widget top is at viewport bottom, 1 when widget bottom is at viewport top
      final animationRange = viewportBottom - viewportTop + widgetHeight;
      final progress = ((viewportBottom - widgetTop) / animationRange).clamp(0.0, 1.0);
      
      if (mounted) {
        setState(() {
          for (int i = 0; i < widget.text.length; i++) {
            // Smaller delay for faster animation
            final delay = (i % 3) * 0.02;
            final adjustedProgress = ((progress - delay).clamp(0.0, 1.0) * 100).clamp(0.0, 100.0);
            _letterOffsets[i] = adjustedProgress;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _key,
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(
              widget.text.length,
              (index) => _buildLetter(widget.text[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetter(String letter, int index) {
    if (letter == ' ') {
      return const SizedBox(width: 20);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _letterOffsets[index] ?? 0.0),
      duration: const Duration(milliseconds: 50), // Faster animation
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return ClipRect(
          child: SizedBox(
            height: widget.fontSize * 1.2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, value),
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      letterSpacing: -2,
                      height: 0.85,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, value - widget.fontSize * 1.2),
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      letterSpacing: -2,
                      height: 0.85,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

