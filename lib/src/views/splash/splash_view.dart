import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/moon_logo.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../home/home_view.dart';

/// Animated brand splash. The logo scales + fades in, the wordmark and tagline
/// rise, then the app cross-fades to the home screen.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashAnim,
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _navTimer = Timer(AppConstants.splashHold, _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeThroughRoute(const HomeView()));
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.nightDeep,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.25),
              radius: 1.1,
              colors: AppColors.nightGradient,
            ),
          ),
          child: Stack(
            children: [
              const _Starfield(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: const MoonLogo(size: 132),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontFamily: AppConstants.fontReading,
                                fontSize: 38,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cream,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppConstants.tagline,
                              style: TextStyle(
                                fontFamily: AppConstants.fontUi,
                                fontSize: 13.5,
                                color: AppColors.gold.withValues(alpha: 0.85),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A handful of faint, static stars for ambience behind the logo.
class _Starfield extends StatelessWidget {
  const _Starfield();

  // Relative positions (x, y, radius) within the screen.
  static const List<List<double>> _stars = [
    [0.18, 0.22, 1.6],
    [0.30, 0.14, 1.0],
    [0.78, 0.20, 1.4],
    [0.86, 0.32, 1.0],
    [0.12, 0.62, 1.2],
    [0.82, 0.70, 1.6],
    [0.68, 0.82, 1.0],
    [0.24, 0.80, 1.3],
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: Stack(
        children: [
          for (final s in _stars)
            Positioned(
              left: s[0] * size.width,
              top: s[1] * size.height,
              child: Container(
                width: s[2] * 2,
                height: s[2] * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cream.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
