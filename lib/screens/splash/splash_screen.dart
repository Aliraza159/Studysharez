// lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';

import '../auth/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _leftIconsController;
  late AnimationController _rightIconsController;
  late AnimationController _logoController;
  late AnimationController _exitController;

  // Animations
  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _exitAnimation;
  late Animation<double> _exitFadeAnimation;

  bool _startExitAnimation = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Left icons slide from left
    _leftIconsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _leftSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _leftIconsController,
      curve: Curves.easeOutBack,
    ));

    // Right icons slide from right
    _rightIconsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rightSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _rightIconsController,
      curve: Curves.easeOutBack,
    ));

    // Logo fade and scale
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _logoFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Exit animation (slide up and fade)
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _exitAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInBack,
    ));
    _exitFadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  void _startAnimationSequence() async {
    // Start left icons
    await Future.delayed(const Duration(milliseconds: 200));
    _leftIconsController.forward();

    // Start right icons slightly after
    await Future.delayed(const Duration(milliseconds: 200));
    _rightIconsController.forward();

    // Show logo after icons settle
    await Future.delayed(const Duration(milliseconds: 400));
    _logoController.forward();

    // Wait and then exit
    await Future.delayed(const Duration(milliseconds: 2000));
    setState(() => _startExitAnimation = true);
    _exitController.forward();

    // Navigate to next screen
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const RoleSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  void dispose() {
    _leftIconsController.dispose();
    _rightIconsController.dispose();
    _logoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return SlideTransition(
            position: _exitAnimation,
            child: FadeTransition(
              opacity: _exitFadeAnimation,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  children: [
                    // === LEFT SIDE ICONS ===

                    // Grade (A+) - Left middle
                    _buildLeftIcon(
                      top: size.height * 0.38,
                      left: 45,
                      asset: 'assets/images/grade.png',
                      size: 70,
                    ),

                    // Open Book - Bottom left
                    _buildLeftIcon(
                      top: size.height * 0.85,
                      left: 20,
                      asset: 'assets/images/open_book.png',
                      size: 70,
                    ),

                    // === RIGHT SIDE ICONS ===

                    // Closed Book - Top center-left
                    _buildRightIcon(
                      top: size.height * 0.12,
                      left: size.width * 0.32,
                      asset: 'assets/images/close_book.png',
                      size: 65,
                    ),

                    // Graduate - Right side upper
                    _buildRightIcon(
                      top: size.height * 0.28,
                      right: 55,
                      asset: 'assets/images/graduate.png',
                      size: 70,
                    ),

                    // Certificate - Bottom right
                    _buildRightIcon(
                      top: size.height * 0.75,
                      right: 45,
                      asset: 'assets/images/certificate.png',
                      size: 60,
                    ),

                    // === CENTER ICONS ===

                    // Atom - Center below logo
                    _buildCenterIcon(
                      top: size.height * 0.58,
                      asset: 'assets/images/Atom.png',
                      size: 75,
                    ),

                    // === LOGO ===
                    Positioned(
                      top: size.height * 0.42,
                      left: 0,
                      right: 0,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Center(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Left side icons (slide from left)
  Widget _buildLeftIcon({
    required double top,
    double? left,
    double? right,
    required String asset,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: SlideTransition(
        position: _leftSlideAnimation,
        child: _IconBadge(asset: asset, size: size),
      ),
    );
  }

  // Right side icons (slide from right)
  Widget _buildRightIcon({
    required double top,
    double? left,
    double? right,
    required String asset,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: SlideTransition(
        position: _rightSlideAnimation,
        child: _IconBadge(asset: asset, size: size),
      ),
    );
  }

  // Center icons (fade in with logo)
  Widget _buildCenterIcon({
    required double top,
    required String asset,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _logoFadeAnimation,
        child: ScaleTransition(
          scale: _logoScaleAnimation,
          child: Center(
            child: _IconBadge(asset: asset, size: size),
          ),
        ),
      ),
    );
  }
}

// Reusable icon badge with shadow
class _IconBadge extends StatelessWidget {
  final String asset;
  final double size;

  const _IconBadge({
    required this.asset,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}