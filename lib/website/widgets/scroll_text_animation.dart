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
    
    // --- FIX START: Trigger calculation immediately after first layout ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll(); 
    });
    // --- FIX END ---
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
    // Check if the context and renderObject are actually ready
    final context = _key.currentContext;
    if (context == null) return;
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final widgetTop = position.dy;
    final widgetHeight = renderBox.size.height;
    
    // Relax the viewport logic slightly to ensure it triggers
    final viewportTop = screenHeight * 0.2; // Trigger earlier (was 0.4)
    
    final widgetBottom = widgetTop + widgetHeight;
    
    // Logic to determine visibility
    // We calculate visibility regardless of whether it's "entering" or "exiting" 
    // to ensure it renders if it lands right in the middle on load.
    if (widgetBottom > 0 && widgetTop < screenHeight) {
       // Calculate a normalized progress 0.0 -> 1.0
       // 0.0 = widget is at bottom of screen
       // 1.0 = widget is at top of screen
       final progress = 1.0 - (widgetTop / (screenHeight * 0.6));

      if (mounted) {
        setState(() {
          for (int i = 0; i < widget.text.length; i++) {
            final delay = (i % 3) * 0.05;
            // Ensure progress forces full visibility if we are well past the trigger point
            double finalVal = ((progress - delay) * 100).clamp(0.0, 100.0);
            
            // If the user has scrolled past this section, keep it fully visible
            if (widgetTop < viewportTop) finalVal = 100.0;
            
            _letterOffsets[i] = finalVal;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _key,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(
            widget.text.length,
            (index) => _buildLetter(widget.text[index], index),
          ),
        ),
      ),
    );
  }

  Widget _buildLetter(String letter, int index) {
    if (letter == ' ') {
      return const SizedBox(width: 20);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _letterOffsets[index] ?? 0.0),
      duration: const Duration(milliseconds: 300), // Increased slightly for smoothness
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

