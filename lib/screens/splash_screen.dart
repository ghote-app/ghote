import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onAnimationComplete});
  
  final VoidCallback onAnimationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/AppIcon/Ghote_opening_animation.mp4');
    await _videoController.initialize();
    _videoController.setPlaybackSpeed(1.5); // 1.5倍速度播放
    _videoController.setLooping(false); // 不循環播放
    _videoController.setVolume(0.0); // 靜音播放
    _videoController.play();
    
    setState(() {
      _isVideoInitialized = true;
    });
    
    // 監聽視頻播放完成（提前1秒結束）
    _videoController.addListener(() {
      if (_videoController.value.isInitialized && 
          _videoController.value.duration.inMilliseconds > 0) {
        // 計算提前1秒的結束時間
        final Duration targetDuration = _videoController.value.duration - const Duration(seconds: 1);
        
        if (_videoController.value.position >= targetDuration) {
          // 視頻播放到提前1秒的位置，立即跳轉
          if (_timer == null) {
            widget.onAnimationComplete();
          }
        }
      }
    });
    
    _startAnimation();
    
    // 備用定時器：如果視頻播放檢測失敗，最多等待 10 秒後跳轉
    Timer(const Duration(seconds: 10), () {
      if (_timer == null) {
        _timer = Timer(const Duration(milliseconds: 500), () {
          widget.onAnimationComplete();
        });
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 750), // 2倍速度：1500/2
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 2倍速度：2000/2
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimation() {
    _fadeController.forward();
    _scaleController.forward();
    
    // 不再使用固定定時器，改由視頻播放完成事件控制跳轉
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _videoController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Video Animation - 2倍速度播放，無聲音
                _isVideoInitialized
                    ? Container(
                        width: 320,
                        height: 320,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _videoController.value.size.width,
                              height: _videoController.value.size.height,
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(
                        width: 320,
                        height: 320,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                const Text(
                  'Ghote',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learning & Knowledge Organization',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
