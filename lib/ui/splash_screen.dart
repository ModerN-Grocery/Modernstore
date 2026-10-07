import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modern_grocery/ui/admin/admin_navibar.dart';
import 'package:modern_grocery/ui/bottom_navigationbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modern_grocery/ui/onboarding_page.dart';
// Optimized: RepaintBoundary + split AnimatedBuilders to minimize unnecessary widget rebuilds

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;
  late AnimationController _progressController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _leafFloatAnimation;

  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  late Animation<double> _badgesFadeAnimation;
  late Animation<Offset> _badgesSlideAnimation;

  late Animation<double> _progressAnimation;

  String UserId = '';

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 2. Continuous floating hover animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 3. Progress bar animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Logo card scale & fade
    _scaleAnimation = Tween<double>(begin: 0.76, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Text slide & fade
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Badges slide & fade
    _badgesFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
      ),
    );

    _badgesSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // Hover float for logo card and leaves
    _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    _leafFloatAnimation = Tween<double>(begin: -3.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // Progress bar fill
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _mainController.forward().then((_) {
      if (mounted) {
        _floatController.repeat(reverse: true);
      }
    });

    _progressController.forward();

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Checking login status...');
    print('Token from prefs: "$token"');
    print('Active appFlavor: "$appFlavor"');

    final role = prefs.getString('role');
    final userType = prefs.getString('userType');
    final isAdminFlag = prefs.getBool('isAdmin');
    UserId = prefs.getString('userId') ?? '';

    final bool isAdmin = role == 'admin' ||
        role == 'Admin' ||
        userType == 'admin' ||
        userType == 'Admin' ||
        isAdminFlag == true;

    Timer(
      const Duration(milliseconds: 2900),
      () {
        if (!mounted) return;

        if (token != null && token.isNotEmpty && UserId.isNotEmpty) {
          if (appFlavor == 'user') {
            // User app flavor: ONLY regular users allowed! Admin accounts are blocked.
            if (isAdmin) {
              prefs.clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const OnboardingPage()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => NavigationBarWidget(initialIndex: 0)),
              );
            }
          } else if (appFlavor == 'admin') {
            // Admin app flavor: ONLY admins allowed! Regular users are blocked.
            if (isAdmin) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminNavibar()),
              );
            } else {
              prefs.clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const OnboardingPage()),
              );
            }
          } else {
            // Standard / default single app routing
            if (isAdmin) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminNavibar()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => NavigationBarWidget(initialIndex: 0)),
              );
            }
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingPage()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdminFlavor = appFlavor == 'admin';

    if (isAdminFlavor) {
      return _buildAdminSplashScreen(context);
    }
    return _buildUserSplashScreen(context);
  }

  // ─────────────────────────────────────────────────────────────
  // User App Splash Screen (Exact match to requested modern UI)
  // ─────────────────────────────────────────────────────────────
  Widget _buildUserSplashScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF4),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFEFDF9),
              Color(0xFFFAF6EC),
              Color(0xFFF7F1DE),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle warm ambient radial background glow
              // RepaintBoundary: static glow never repaints with animations
              Positioned(
                top: 130.h,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: Center(
                    child: Container(
                      width: 300.w,
                      height: 300.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFDE8B5).withOpacity(0.4),
                            blurRadius: 100,
                            spreadRadius: 35,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Decorative Floating Green Leaf (Top-Right of text area)
              // RepaintBoundary isolates continuous float animation repaints
              Positioned(
                top: 410.h,
                right: 34.w,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _leafFloatAnimation.value),
                        child: Transform.rotate(
                          angle: 0.35,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 17.w,
                      height: 17.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF67B995).withOpacity(0.85),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(13.r),
                          bottomRight: Radius.circular(13.r),
                          topRight: Radius.circular(3.r),
                          bottomLeft: Radius.circular(3.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Decorative Floating Golden Leaf (Left side near badges)
              Positioned(
                top: 545.h,
                left: 32.w,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_leafFloatAnimation.value),
                        child: Transform.rotate(
                          angle: -0.4,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      Icons.eco_rounded,
                      color: const Color(0xFFDE9E28).withOpacity(0.9),
                      size: 19.sp,
                    ),
                  ),
                ),
              ),

              // Main Layout Column
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),

                        // 1. Logo Card with thick rounded frame & soft floating hover
                        // Split into two AnimatedBuilders: entrance (once) + float (continuous)
                        // This avoids full logo-card rebuild on every float frame tick
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 232.w,
                                height: 232.w,
                                padding: EdgeInsets.all(15.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF5E8),
                                  borderRadius: BorderRadius.circular(46.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEAD8AD).withOpacity(0.38),
                                      blurRadius: 36,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(34.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(16.w),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/New Icon.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 38.h),

                        // 2. Titles & Subtitle
                        FadeTransition(
                          opacity: _textFadeAnimation,
                          child: SlideTransition(
                            position: _textSlideAnimation,
                            child: Column(
                              children: [
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 27.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                      height: 1.25,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Fresh Groceries,\n',
                                        style: TextStyle(
                                          color: Color(0xFF1B1A16),
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Delivered Daily.',
                                        style: TextStyle(
                                          color: Color(0xFFDE9E28),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Text(
                                    'Farm-fresh harvest & essentials to your doorstep in minutes',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF6B665A),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 22.h),

                       

                        SizedBox(height: 70.h),

                        // 4. Progress bar with leading Sparkle Icon
                        // RepaintBoundary: limits frame repaints to only this widget
                        RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            final double progress = _progressAnimation.value.clamp(0.0, 1.0);
                            const double barWidth = 190.0;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: barWidth.w,
                                  height: 16.h,
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      // Background track
                                      Container(
                                        width: barWidth.w,
                                        height: 4.5.h,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8E2D2),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                      ),
                                      // Active fill
                                      Container(
                                        width: (barWidth * progress).w,
                                        height: 4.5.h,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFF3C759),
                                              Color(0xFFDE9E28),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                      ),
                                      // Sparkle indicator at head
                                      Positioned(
                                        left: ((barWidth * progress) - 5.0).clamp(0.0, barWidth - 8.0).w,
                                        child: Icon(
                                          Icons.auto_awesome,
                                          size: 13.sp,
                                          color: const Color(0xFFDE9E28),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 10.h),

                               
                              ],
                            );
                          },
                        ),
                        ), // RepaintBoundary close

                        SizedBox(height: 16.h),

                        // 5. Version & Network Footer
                        Text(
                          'v1.0.7 • Sustainable & Local Grocery Network',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFA19D94),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // 6. Home indicator pill
                        Container(
                          width: 134.w,
                          height: 4.5.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDD8CC),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),

                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Feature Chip / Pill Badge Helper
  // ─────────────────────────────────────────────────────────────
  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: const Color(0xFFEFD79F),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAD8AD).withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: const Color(0xFFDE9E28),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262420),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Admin App Splash Screen (Preserved for Admin flavor)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAdminSplashScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5E9B5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 220.h,
              width: 220.w,
              child: Image.asset(
                'assets/MODERN.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Admin Management Portal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5A4A1C),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: 26.w,
              height: 26.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF8B6B23),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
