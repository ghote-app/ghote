import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import '../widgets/glass_button.dart';
import 'dart:ui'; // Import for ImageFilter
import '../utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final void Function(String name, String email) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Use SingleTickerProviderStateMixin for animation controller
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Unfocus to hide keyboard
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    
    // Haptic feedback for a more tactile feel
    HapticFeedback.lightImpact();

    await Future<void>.delayed(const Duration(seconds: 2));
    final String email = _emailController.text.trim().isEmpty
        ? 'demo@ghote.app'
        : _emailController.text.trim();
    final String name =
        email.split('@').first.isEmpty ? 'User' : email.split('@').first;
    if (!mounted) return;
    widget.onLogin(name, email);
    // No need to set isLoading to false as we are navigating away
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          // A subtle gradient background adds more depth
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                Colors.grey.shade900.withValues(alpha: 0.8),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: Responsive.pagePadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(),
                  // Animated Header
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildHeader(),
                    ),
                  ),
                  SizedBox(height: Responsive.spaceL(context)),

                  // Animated Form Fields
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _emailController,
                            hint: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon:
                                const Icon(Icons.alternate_email, color: Colors.white70, size: 20),
                          ),
                          SizedBox(height: Responsive.spaceS(context)),
                          _buildInputField(
                            controller: _passwordController,
                            hint: 'Enter your password',
                            obscureText: !_showPassword,
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _showPassword = !_showPassword),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.spaceS(context)),
                  
                  // Animated Forgot Password
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildForgotPasswordButton()),
                  ),

                  SizedBox(height: Responsive.spaceM(context)),

                  // Animated Buttons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                            _buildSignInButton(),
                            SizedBox(height: Responsive.spaceS(context)),
                            _buildDivider(),
                            SizedBox(height: Responsive.spaceS(context)),
                          _buildGoogleSignInButton(),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.asset(
                'assets/images/Ghote_icon_black_background.png',
                width: Responsive.avatarM(context),
                height: Responsive.avatarM(context),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: Responsive.spaceM(context)),
        Text(
          'Welcome Back',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: Responsive.spaceXS(context)),
        Text(
          'Sign in to your account to continue',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    // Using ClipRRect and BackdropFilter for a frosted glass effect
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: Responsive.inputContentPadding(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: GlassButton(
        enabled: !_isLoading,
        onPressed: _isLoading ? null : _handleLogin,
        borderRadius: 16,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Row(
      children: <Widget>[
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: GlassButton(
        enabled: !_isLoading,
        onPressed: _isLoading
            ? null
            : () {
                // Google Sign In - placeholder implementation
                _handleLogin();
              },
        borderRadius: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.login,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}