import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onAnimationComplete});
  
  final VoidCallback onAnimationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/images/Ghote_opening_animation.mp4');
    _videoController.initialize().then((_) {
      setState(() {});
      _videoController.play();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimation() {
    _fadeController.forward();
    
    // 設置定時器，在動畫播放完成後跳轉
    _timer = Timer(const Duration(seconds: 5), () {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 黑色背景
          Container(
            color: Colors.black,
          ),
          
          // 視頻動畫
          if (_videoController.value.isInitialized)
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
